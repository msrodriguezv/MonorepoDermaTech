terraform {
  backend "s3" {
    bucket = "tfstate-prod-dermatech"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}

# ==============================================================================
# PROVIDERS CONFIGURATION (PROD MULTI-ACCOUNT)
# ==============================================================================

# 1. Default Provider (PROD Hub Account)
provider "aws" {
  region  = "us-east-1"
  profile = "prod-dermatech" 
}

# 2. Events Account Provider
provider "aws" {
  alias   = "events"
  region  = "us-east-1"
  profile = "prod-events-dermatech"
}

# 3. State Account Provider
provider "aws" {
  alias   = "state"
  region  = "us-east-1"
  profile = "prod-state-dermatech"
}

# 4. Node A Account Provider
provider "aws" {
  alias   = "node_a"
  region  = "us-east-1"
  profile = "prod-node-a-dermatech"
}

# 5. Node B Account Provider
provider "aws" {
  alias   = "node_b"
  region  = "us-east-1"
  profile = "prod-node-b-dermatech"
}

locals {
  project_name = "dermatech"
  environment  = "prod"
  ami_id       = "ami-051f7e7f6c2f40dc1" # Amazon Linux 2023
  
  # SE ELIMINÓ LA LÓGICA "TODO O NADA" PARA EVITAR EL BORRADO DE RUTAS
}

# ==============================================================================
# 1. NETWORKING LAYER (PROD HUB VPC)
# ==============================================================================
module "networking" {
  source             = "../../modules/aws-networking"
  region             = "us-east-1"
  project_name       = local.project_name
  environment        = local.environment
  vpc_cidr           = var.prod_cidr              
  public_subnet_cidr = "10.0.1.0/24"
  availability_zone  = "us-east-1a"            
}

resource "aws_subnet" "public_b_alb" {
  vpc_id                  = module.networking.vpc_id
  cidr_block              = var.prod_public_subnet_b_cidr
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
# 2. GATEWAY / BASTION LAYER (PROD DATA INJECTED)
# ==============================================================================
module "gateway" {
  source              = "../../modules/aws-gateway-node"
  project_name        = local.project_name
  environment         = local.environment
  vpc_id              = module.networking.vpc_id
  ami_id              = local.ami_id
  public_subnet_id    = module.networking.public_subnet_id
  availability_zone   = "us-east-1a"

  # Prod Networking Data
  bastion_private_ip  = "10.0.1.59"
  eip_allocation_id   = "eipalloc-054a2c5b06cb85f2f"

  # Hybrid Bridge Connection
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
# 4. ADMIN CONNECTIVITY: PROD HUB <-> ALL SPOKES (CORREGIDO)
# ==============================================================================

# --- A. PROD <-> EVENTS ---
resource "aws_vpc_peering_connection" "prod_to_events" {
  count         = var.events_vpc_id != "" ? 1 : 0
  vpc_id        = module.networking.vpc_id
  peer_vpc_id   = var.events_vpc_id
  peer_owner_id = var.events_account_id
  peer_region   = "us-east-1"
  tags          = { Name = "prod-to-events-peering" }
}
resource "aws_vpc_peering_connection_accepter" "events_accept_prod" {
  provider                  = aws.events
  count                     = var.events_vpc_id != "" ? 1 : 0
  vpc_peering_connection_id = aws_vpc_peering_connection.prod_to_events[0].id
  auto_accept               = true
}
resource "aws_route" "prod_route_events" {
  count                     = var.events_vpc_id != "" ? 1 : 0
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.events_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.prod_to_events[0].id
}
resource "aws_route" "events_route_prod" {
  provider                  = aws.events
  count                     = var.events_vpc_id != "" ? 1 : 0
  route_table_id            = data.aws_route_table.events_rt.id
  destination_cidr_block    = var.prod_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.prod_to_events[0].id
}

# --- B. PROD <-> STATE ---
resource "aws_vpc_peering_connection" "prod_to_state" {
  count         = var.state_vpc_id != "" ? 1 : 0
  vpc_id        = module.networking.vpc_id
  peer_vpc_id   = var.state_vpc_id
  peer_owner_id = var.state_account_id
  tags          = { Name = "prod-to-state-peering" }
}
resource "aws_vpc_peering_connection_accepter" "state_accept_prod" {
  provider                  = aws.state
  count                     = var.state_vpc_id != "" ? 1 : 0
  vpc_peering_connection_id = aws_vpc_peering_connection.prod_to_state[0].id
  auto_accept               = true
}
resource "aws_route" "prod_route_state" {
  count                     = var.state_vpc_id != "" ? 1 : 0
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.state_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.prod_to_state[0].id
}
resource "aws_route" "state_route_prod" {
  provider                  = aws.state
  count                     = var.state_vpc_id != "" ? 1 : 0
  route_table_id            = data.aws_route_table.state_rt.id
  destination_cidr_block    = var.prod_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.prod_to_state[0].id
}

# --- C. PROD <-> NODE A ---
resource "aws_vpc_peering_connection" "prod_to_node_a" {
  count         = var.node_a_vpc_id != "" ? 1 : 0
  vpc_id        = module.networking.vpc_id
  peer_vpc_id   = var.node_a_vpc_id
  peer_owner_id = var.node_a_account_id
  tags          = { Name = "prod-to-node-a-peering" }
}
resource "aws_vpc_peering_connection_accepter" "node_a_accept_prod" {
  provider                  = aws.node_a
  count                     = var.node_a_vpc_id != "" ? 1 : 0
  vpc_peering_connection_id = aws_vpc_peering_connection.prod_to_node_a[0].id
  auto_accept               = true
}
resource "aws_route" "prod_route_node_a" {
  count                     = var.node_a_vpc_id != "" ? 1 : 0
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.node_a_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.prod_to_node_a[0].id
}
resource "aws_route" "node_a_route_prod" {
  provider                  = aws.node_a
  count                     = var.node_a_vpc_id != "" ? 1 : 0
  route_table_id            = data.aws_route_table.node_a_rt.id
  destination_cidr_block    = var.prod_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.prod_to_node_a[0].id
}

# --- D. PROD <-> NODE B ---
resource "aws_vpc_peering_connection" "prod_to_node_b" {
  count         = var.node_b_vpc_id != "" ? 1 : 0
  vpc_id        = module.networking.vpc_id
  peer_vpc_id   = var.node_b_vpc_id
  peer_owner_id = var.node_b_account_id
  tags          = { Name = "prod-to-node-b-peering" }
}
resource "aws_vpc_peering_connection_accepter" "node_b_accept_prod" {
  provider                  = aws.node_b
  count                     = var.node_b_vpc_id != "" ? 1 : 0
  vpc_peering_connection_id = aws_vpc_peering_connection.prod_to_node_b[0].id
  auto_accept               = true
}
resource "aws_route" "prod_route_node_b" {
  count                     = var.node_b_vpc_id != "" ? 1 : 0
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.node_b_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.prod_to_node_b[0].id
}
resource "aws_route" "node_b_route_prod" {
  provider                  = aws.node_b
  count                     = var.node_b_vpc_id != "" ? 1 : 0
  route_table_id            = data.aws_route_table.node_b_rt.id
  destination_cidr_block    = var.prod_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.prod_to_node_b[0].id
}

# ==============================================================================
# 5. CONNECTIVITY: EVENTS <-> STATE (BACKEND SYNC) (CORREGIDO)
# ==============================================================================
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

# ==============================================================================
# 6. CONNECTIVITY: APP NODES <-> BACKEND (CORREGIDO)
# ==============================================================================

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

# A. SECURITY GROUP FOR ALB
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

# B. LOAD BALANCER RESOURCE
resource "aws_lb" "main_alb" {
  name               = "${local.project_name}-${local.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  
  # References both Hub Subnets to satisfy Multi-AZ requirements.
  subnets            = [module.networking.public_subnet_id, aws_subnet.public_b_alb.id]

  tags = { Name = "${local.project_name}-${local.environment}-alb" }
}

# C. TARGET GROUPS (CROSS-ACCOUNT ROUTING VIA IP)
resource "aws_lb_target_group" "frontend" {
  name        = "tg-prod-frontend"
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
  name        = "tg-prod-api-gateway"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = module.networking.vpc_id
  target_type = "ip"

  health_check {
    path = "/health"
    port = "3000"
  }
}

# D. LISTENER AND ROUTING RULES
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

# E. TARGET ATTACHMENTS (PROD NODES)
resource "aws_lb_target_group_attachment" "node_a_web" {
  target_group_arn  = aws_lb_target_group.frontend.arn
  target_id         = "10.3.1.10" # Node A PROD IP
  port              = 80
  availability_zone = "all"
}

resource "aws_lb_target_group_attachment" "node_b_web" {
  target_group_arn  = aws_lb_target_group.frontend.arn
  target_id         = "10.4.1.10" # Node B PROD IP
  port              = 80
  availability_zone = "all"
}

resource "aws_lb_target_group_attachment" "node_a_api" {
  target_group_arn  = aws_lb_target_group.api.arn
  target_id         = "10.3.1.10"
  port              = 3000
  availability_zone = "all"
}

resource "aws_lb_target_group_attachment" "node_b_api" {
  target_group_arn  = aws_lb_target_group.api.arn
  target_id         = "10.4.1.10"
  port              = 3000
  availability_zone = "all"
}