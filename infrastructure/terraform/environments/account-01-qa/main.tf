terraform {
  backend "s3" {
    bucket = "tfstate-qa-dermatech"
    key    = "qa/terraform.tfstate"
    region = "us-east-1"
  }
}

# ==============================================================================
# PROVIDERS CONFIGURATION (MULTI-ACCOUNT ORCHESTRATION)
# ==============================================================================

provider "aws" {
  region  = "us-east-1"
  profile = "qa-dermatech" 
}

provider "aws" {
  alias   = "events"
  region  = "us-east-1"
  profile = "events-dermatech"
}

provider "aws" {
  alias   = "state"
  region  = "us-east-1"
  profile = "state-dermatech"
}

provider "aws" {
  alias   = "node_a"
  region  = "us-east-1"
  profile = "node-a-dermatech"
}

provider "aws" {
  alias   = "node_b"
  region  = "us-east-1"
  profile = "node-b-dermatech"
}

locals {
  project_name = "dermatech"
  environment  = "qa"
  ami_id       = "ami-051f7e7f6c2f40dc1" # Amazon Linux 2023
  
  # SE ELIMINÓ LA LÓGICA "TODO O NADA" (deploy_connectivity) QUE CAUSABA EL ERROR
}

# ==============================================================================
# 1. NETWORKING LAYER (QA HUB VPC)
# ==============================================================================
module "networking" {
  source             = "../../modules/aws-networking"
  region             = "us-east-1"
  project_name       = local.project_name
  environment        = local.environment
  vpc_cidr           = var.qa_cidr              
  public_subnet_cidr = "10.0.1.0/24"
  availability_zone  = "us-east-1a"            
}

resource "aws_subnet" "public_b_alb" {
  vpc_id                  = module.networking.vpc_id
  cidr_block              = var.qa_public_subnet_b_cidr 
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = {
    Name        = "${local.project_name}-${local.environment}-public-1b-alb"
    Environment = local.environment
  }
}

resource "aws_route_table_association" "public_b_assoc" {
  subnet_id      = aws_subnet.public_b_alb.id
  route_table_id = module.networking.public_route_table_id
}

# ==============================================================================
# 2. GATEWAY / BASTION LAYER
# ==============================================================================
module "gateway" {
  source              = "../../modules/aws-gateway-node"
  project_name        = local.project_name
  environment         = local.environment
  vpc_id              = module.networking.vpc_id
  ami_id              = local.ami_id
  public_subnet_id    = module.networking.public_subnet_id
  availability_zone   = "us-east-1a"
  bastion_private_ip  = "10.0.1.59"
  eip_allocation_id   = "eipalloc-04a19075ece27ac49"

  alb_dns_name        = aws_lb.main_alb.dns_name 
}

# ==============================================================================
# 3. DATA SOURCES: REMOTE ROUTE TABLES LOOKUP
# ==============================================================================

data "aws_route_table" "events_rt" {
  provider = aws.events
  vpc_id   = var.events_vpc_id
  filter {
    name   = "tag:Name"
    values = ["*-public-rt"] 
  }
}

data "aws_route_table" "state_rt" {
  provider = aws.state
  vpc_id   = var.state_vpc_id
  filter {
    name   = "tag:Name"
    values = ["*-public-rt"]
  }
}

data "aws_route_table" "node_a_rt" {
  provider = aws.node_a
  vpc_id   = var.node_a_vpc_id
  filter {
    name   = "tag:Name"
    values = ["*-public-rt"]
  }
}

data "aws_route_table" "node_b_rt" {
  provider = aws.node_b
  vpc_id   = var.node_b_vpc_id
  filter {
    name   = "tag:Name"
    values = ["*-public-rt"]
  }
}

# ==============================================================================
# 4. PEERINGS & ROUTES (CORREGIDO: INDEPENDENCIA TOTAL)
# ==============================================================================

# --- A. QA <-> EVENTS ---
resource "aws_vpc_peering_connection" "qa_to_events" {
  count         = var.events_vpc_id != "" ? 1 : 0
  vpc_id        = module.networking.vpc_id
  peer_vpc_id   = var.events_vpc_id
  peer_owner_id = var.events_account_id
  peer_region   = "us-east-1"
  tags          = { Name = "qa-to-events-peering" }
}
resource "aws_vpc_peering_connection_accepter" "events_accept_qa" {
  provider                  = aws.events
  count                     = var.events_vpc_id != "" ? 1 : 0
  vpc_peering_connection_id = aws_vpc_peering_connection.qa_to_events[0].id
  auto_accept               = true
}
resource "aws_route" "qa_route_events" {
  count                     = var.events_vpc_id != "" ? 1 : 0
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.events_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.qa_to_events[0].id
}
resource "aws_route" "events_route_qa" {
  provider                  = aws.events
  count                     = var.events_vpc_id != "" ? 1 : 0
  route_table_id            = data.aws_route_table.events_rt.id
  destination_cidr_block    = var.qa_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.qa_to_events[0].id
}

# --- B. QA <-> STATE ---
resource "aws_vpc_peering_connection" "qa_to_state" {
  count         = var.state_vpc_id != "" ? 1 : 0
  vpc_id        = module.networking.vpc_id
  peer_vpc_id   = var.state_vpc_id
  peer_owner_id = var.state_account_id
  tags          = { Name = "qa-to-state-peering" }
}
resource "aws_vpc_peering_connection_accepter" "state_accept_qa" {
  provider                  = aws.state
  count                     = var.state_vpc_id != "" ? 1 : 0
  vpc_peering_connection_id = aws_vpc_peering_connection.qa_to_state[0].id
  auto_accept               = true
}
resource "aws_route" "qa_route_state" {
  count                     = var.state_vpc_id != "" ? 1 : 0
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.state_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.qa_to_state[0].id
}
resource "aws_route" "state_route_qa" {
  provider                  = aws.state
  count                     = var.state_vpc_id != "" ? 1 : 0
  route_table_id            = data.aws_route_table.state_rt.id
  destination_cidr_block    = var.qa_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.qa_to_state[0].id
}

# --- C. QA <-> NODE A ---
resource "aws_vpc_peering_connection" "qa_to_node_a" {
  count         = var.node_a_vpc_id != "" ? 1 : 0
  vpc_id        = module.networking.vpc_id
  peer_vpc_id   = var.node_a_vpc_id
  peer_owner_id = var.node_a_account_id
  tags          = { Name = "qa-to-node-a-peering" }
}
resource "aws_vpc_peering_connection_accepter" "node_a_accept_qa" {
  provider                  = aws.node_a
  count                     = var.node_a_vpc_id != "" ? 1 : 0
  vpc_peering_connection_id = aws_vpc_peering_connection.qa_to_node_a[0].id
  auto_accept               = true
}
resource "aws_route" "qa_route_node_a" {
  count                     = var.node_a_vpc_id != "" ? 1 : 0
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.node_a_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.qa_to_node_a[0].id
}
resource "aws_route" "node_a_route_qa" {
  provider                  = aws.node_a
  count                     = var.node_a_vpc_id != "" ? 1 : 0
  route_table_id            = data.aws_route_table.node_a_rt.id
  destination_cidr_block    = var.qa_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.qa_to_node_a[0].id
}

# --- D. QA <-> NODE B ---
resource "aws_vpc_peering_connection" "qa_to_node_b" {
  count         = var.node_b_vpc_id != "" ? 1 : 0
  vpc_id        = module.networking.vpc_id
  peer_vpc_id   = var.node_b_vpc_id
  peer_owner_id = var.node_b_account_id
  tags          = { Name = "qa-to-node-b-peering" }
}
resource "aws_vpc_peering_connection_accepter" "node_b_accept_qa" {
  provider                  = aws.node_b
  count                     = var.node_b_vpc_id != "" ? 1 : 0
  vpc_peering_connection_id = aws_vpc_peering_connection.qa_to_node_b[0].id
  auto_accept               = true
}
resource "aws_route" "qa_route_node_b" {
  count                     = var.node_b_vpc_id != "" ? 1 : 0
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.node_b_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.qa_to_node_b[0].id
}
resource "aws_route" "node_b_route_qa" {
  provider                  = aws.node_b
  count                     = var.node_b_vpc_id != "" ? 1 : 0
  route_table_id            = data.aws_route_table.node_b_rt.id
  destination_cidr_block    = var.qa_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.qa_to_node_b[0].id
}

# ==============================================================================
# 5. CONNECTIVITY: SPOKES (CORREGIDO: INDEPENDENCIA TOTAL)
# ==============================================================================

# --- EVENTS <-> STATE ---
resource "aws_vpc_peering_connection" "events_to_state" {
  provider      = aws.events
  count         = (var.events_vpc_id != "" && var.state_vpc_id != "") ? 1 : 0
  vpc_id        = var.events_vpc_id
  peer_vpc_id   = var.state_vpc_id
  peer_owner_id = var.state_account_id
  tags          = { Name = "events-to-state-peering" }
}
resource "aws_vpc_peering_connection_accepter" "state_accept_events" {
  provider                  = aws.state
  count                     = (var.events_vpc_id != "" && var.state_vpc_id != "") ? 1 : 0
  vpc_peering_connection_id = aws_vpc_peering_connection.events_to_state[0].id
  auto_accept               = true
}
resource "aws_route" "events_route_state" {
  provider                  = aws.events
  count                     = (var.events_vpc_id != "" && var.state_vpc_id != "") ? 1 : 0
  route_table_id            = data.aws_route_table.events_rt.id
  destination_cidr_block    = var.state_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.events_to_state[0].id
}
resource "aws_route" "state_route_events" {
  provider                  = aws.state
  count                     = (var.events_vpc_id != "" && var.state_vpc_id != "") ? 1 : 0
  route_table_id            = data.aws_route_table.state_rt.id
  destination_cidr_block    = var.events_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.events_to_state[0].id
}

# --- A. NODE A -> EVENTS ---
resource "aws_vpc_peering_connection" "node_a_events" {
  provider      = aws.node_a
  count         = (var.node_a_vpc_id != "" && var.events_vpc_id != "") ? 1 : 0
  vpc_id        = var.node_a_vpc_id
  peer_vpc_id   = var.events_vpc_id
  peer_owner_id = var.events_account_id
  tags          = { Name = "node-a-to-events" }
}
resource "aws_vpc_peering_connection_accepter" "events_accept_node_a" {
  provider                  = aws.events
  count                     = (var.node_a_vpc_id != "" && var.events_vpc_id != "") ? 1 : 0
  vpc_peering_connection_id = aws_vpc_peering_connection.node_a_events[0].id
  auto_accept               = true
}
resource "aws_route" "node_a_to_events" {
  provider                  = aws.node_a
  count                     = (var.node_a_vpc_id != "" && var.events_vpc_id != "") ? 1 : 0
  route_table_id            = data.aws_route_table.node_a_rt.id
  destination_cidr_block    = var.events_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.node_a_events[0].id
}
resource "aws_route" "events_to_node_a" {
  provider                  = aws.events
  count                     = (var.node_a_vpc_id != "" && var.events_vpc_id != "") ? 1 : 0
  route_table_id            = data.aws_route_table.events_rt.id
  destination_cidr_block    = var.node_a_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.node_a_events[0].id
}

# --- B. NODE A -> STATE ---
resource "aws_vpc_peering_connection" "node_a_state" {
  provider      = aws.node_a
  count         = (var.node_a_vpc_id != "" && var.state_vpc_id != "") ? 1 : 0
  vpc_id        = var.node_a_vpc_id
  peer_vpc_id   = var.state_vpc_id
  peer_owner_id = var.state_account_id
  tags          = { Name = "node-a-to-state" }
}
resource "aws_vpc_peering_connection_accepter" "state_accept_node_a" {
  provider                  = aws.state
  count                     = (var.node_a_vpc_id != "" && var.state_vpc_id != "") ? 1 : 0
  vpc_peering_connection_id = aws_vpc_peering_connection.node_a_state[0].id
  auto_accept               = true
}
resource "aws_route" "node_a_to_state" {
  provider                  = aws.node_a
  count                     = (var.node_a_vpc_id != "" && var.state_vpc_id != "") ? 1 : 0
  route_table_id            = data.aws_route_table.node_a_rt.id
  destination_cidr_block    = var.state_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.node_a_state[0].id
}
resource "aws_route" "state_to_node_a" {
  provider                  = aws.state
  count                     = (var.node_a_vpc_id != "" && var.state_vpc_id != "") ? 1 : 0
  route_table_id            = data.aws_route_table.state_rt.id
  destination_cidr_block    = var.node_a_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.node_a_state[0].id
}

# --- C. NODE B -> EVENTS ---
resource "aws_vpc_peering_connection" "node_b_events" {
  provider      = aws.node_b
  count         = (var.node_b_vpc_id != "" && var.events_vpc_id != "") ? 1 : 0
  vpc_id        = var.node_b_vpc_id
  peer_vpc_id   = var.events_vpc_id
  peer_owner_id = var.events_account_id
  tags          = { Name = "node-b-to-events" }
}
resource "aws_vpc_peering_connection_accepter" "events_accept_node_b" {
  provider                  = aws.events
  count                     = (var.node_b_vpc_id != "" && var.events_vpc_id != "") ? 1 : 0
  vpc_peering_connection_id = aws_vpc_peering_connection.node_b_events[0].id
  auto_accept               = true
}
resource "aws_route" "node_b_to_events" {
  provider                  = aws.node_b
  count                     = (var.node_b_vpc_id != "" && var.events_vpc_id != "") ? 1 : 0
  route_table_id            = data.aws_route_table.node_b_rt.id
  destination_cidr_block    = var.events_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.node_b_events[0].id
}
resource "aws_route" "events_to_node_b" {
  provider                  = aws.events
  count                     = (var.node_b_vpc_id != "" && var.events_vpc_id != "") ? 1 : 0
  route_table_id            = data.aws_route_table.events_rt.id
  destination_cidr_block    = var.node_b_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.node_b_events[0].id
}

# --- D. NODE B -> STATE ---
resource "aws_vpc_peering_connection" "node_b_state" {
  provider      = aws.node_b
  count         = (var.node_b_vpc_id != "" && var.state_vpc_id != "") ? 1 : 0
  vpc_id        = var.node_b_vpc_id
  peer_vpc_id   = var.state_vpc_id
  peer_owner_id = var.state_account_id
  tags          = { Name = "node-b-to-state" }
}
resource "aws_vpc_peering_connection_accepter" "state_accept_node_b" {
  provider                  = aws.state
  count                     = (var.node_b_vpc_id != "" && var.state_vpc_id != "") ? 1 : 0
  vpc_peering_connection_id = aws_vpc_peering_connection.node_b_state[0].id
  auto_accept               = true
}
resource "aws_route" "node_b_to_state" {
  provider                  = aws.node_b
  count                     = (var.node_b_vpc_id != "" && var.state_vpc_id != "") ? 1 : 0
  route_table_id            = data.aws_route_table.node_b_rt.id
  destination_cidr_block    = var.state_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.node_b_state[0].id
}
resource "aws_route" "state_to_node_b" {
  provider                  = aws.state
  count                     = (var.node_b_vpc_id != "" && var.state_vpc_id != "") ? 1 : 0
  route_table_id            = data.aws_route_table.state_rt.id
  destination_cidr_block    = var.node_b_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.node_b_state[0].id
}

# ==============================================================================
# 7. MASTER PROXY LAYER (APPLICATION LOAD BALANCER)
# ==============================================================================

resource "aws_security_group" "alb_sg" {
  name        = "${local.project_name}-${local.environment}-alb-sg"
  description = "Global Entry Point for Web Traffic"
  vpc_id      = module.networking.vpc_id

  ingress {
    description = "Public HTTP Access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow Internal Routing to Peer VPCs"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.project_name}-${local.environment}-alb-sg" }
}

resource "aws_lb" "main_alb" {
  name               = "${local.project_name}-${local.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [module.networking.public_subnet_id, aws_subnet.public_b_alb.id]

  tags = { Name = "${local.project_name}-${local.environment}-alb" }
}

resource "aws_lb_target_group" "frontend" {
  name        = "tg-qa-frontend"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.networking.vpc_id
  target_type = "ip"

  health_check {
    path = "/health"
    port = "80"
  }
}

resource "aws_lb_target_group" "api" {
  name        = "tg-qa-api-gateway"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = module.networking.vpc_id
  target_type = "ip"

  health_check {
    path = "/health"
    port = "3000"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener_rule" "api_routing" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

resource "aws_lb_target_group_attachment" "node_a_web" {
  target_group_arn = aws_lb_target_group.frontend.arn
  target_id        = "10.3.1.10"
  port             = 80
  availability_zone = "all"
}

resource "aws_lb_target_group_attachment" "node_b_web" {
  target_group_arn = aws_lb_target_group.frontend.arn
  target_id        = "10.4.1.10"
  port             = 80
  availability_zone = "all"
}

resource "aws_lb_target_group_attachment" "node_a_api" {
  target_group_arn = aws_lb_target_group.api.arn
  target_id        = "10.3.1.10"
  port             = 3000
  availability_zone = "all"
}

resource "aws_lb_target_group_attachment" "node_b_api" {
  target_group_arn = aws_lb_target_group.api.arn
  target_id        = "10.4.1.10"
  port             = 3000
  availability_zone = "all"
}