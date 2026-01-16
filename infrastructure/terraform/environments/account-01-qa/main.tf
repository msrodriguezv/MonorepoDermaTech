provider "aws" {
  region  = "us-east-1"
  profile = "qa-dermatech" 
}

locals {
  project_name = "dermatech"
  environment  = "qa"
  ami_id       = "ami-051f7e7f6c2f40dc1" # Amazon Linux 2023
}

# ==============================================================================
# 1. NETWORKING LAYER (HUB)
# ==============================================================================
module "networking" {
  source             = "../../modules/aws-networking"
  region             = "us-east-1"
  project_name       = local.project_name
  environment        = local.environment
  vpc_cidr           = var.qa_cidr            # 10.0.0.0/16
  public_subnet_cidr = "10.0.1.0/24"
  availability_zone  = "us-east-1a"           # Hub located in Zone A
}

# ==============================================================================
# 2. AUTOMATIC DISCOVERY LAYER (DATA SOURCES)
# Purpose: Dynamically fetch VPC IDs using Name Tags for full automation.
# ==============================================================================

# Discover Events VPC
data "aws_vpc" "events_discovery" {
  filter {
    name   = "tag:Name"
    values = ["dermatech-infra-events-vpc"]
  }
}

# Discover State VPC
data "aws_vpc" "state_discovery" {
  filter {
    name   = "tag:Name"
    values = ["dermatech-infra-state-vpc"]
  }
}

# Discover Node A VPC
data "aws_vpc" "node_a_discovery" {
  filter {
    name   = "tag:Name"
    values = ["dermatech-infra-node-a-vpc"]
  }
}

# Discover Node B VPC
data "aws_vpc" "node_b_discovery" {
  filter {
    name   = "tag:Name"
    values = ["dermatech-infra-node-b-vpc"]
  }
}

# ==============================================================================
# 3. GATEWAY / BASTION LAYER
# ==============================================================================
module "gateway" {
  source           = "../../modules/aws-gateway-node"
  project_name     = local.project_name
  environment      = local.environment
  vpc_id           = module.networking.vpc_id
  ami_id           = local.ami_id
  public_subnet_id = module.networking.public_subnet_id
}

# ==============================================================================
# 4. INTERCONNECTION LAYER (VPC PEERING REQUESTS)
# ==============================================================================

# Request to Events
resource "aws_vpc_peering_connection" "qa_to_events" {
  peer_owner_id = var.events_account_id
  peer_vpc_id   = data.aws_vpc.events_discovery.id
  vpc_id        = module.networking.vpc_id
  auto_accept   = false
  tags          = { Name = "qa-to-events-peering" }
}

# Request to State
resource "aws_vpc_peering_connection" "qa_to_state" {
  peer_owner_id = var.state_account_id
  peer_vpc_id   = data.aws_vpc.state_discovery.id
  vpc_id        = module.networking.vpc_id
  auto_accept   = false
  tags          = { Name = "qa-to-state-peering" }
}

# Request to Node A
resource "aws_vpc_peering_connection" "qa_to_node_a" {
  peer_owner_id = var.node_a_account_id
  peer_vpc_id   = data.aws_vpc.node_a_discovery.id
  vpc_id        = module.networking.vpc_id
  auto_accept   = false
  tags          = { Name = "qa-to-node-a-peering" }
}

# Request to Node B
resource "aws_vpc_peering_connection" "qa_to_node_b" {
  peer_owner_id = var.node_b_account_id
  peer_vpc_id   = data.aws_vpc.node_b_discovery.id
  vpc_id        = module.networking.vpc_id
  auto_accept   = false
  tags          = { Name = "qa-to-node-b-peering" }
}

# ==============================================================================
# 5. ROUTING LAYER (ACCESS TO SPOKE NETWORKS)
# ==============================================================================

resource "aws_route" "route_to_events" {
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.events_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.qa_to_events.id
}

resource "aws_route" "route_to_state" {
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.state_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.qa_to_state.id
}

resource "aws_route" "route_to_node_a" {
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.node_a_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.qa_to_node_a.id
}

resource "aws_route" "route_to_node_b" {
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.node_b_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.qa_to_node_b.id
}

# ==============================================================================
# 6. OUTPUTS
# ==============================================================================
output "QA_GATEWAY_PUBLIC_IP" {
  value = module.gateway.final_public_ip
}

output "QA_VPC_ID" {
  value = module.networking.vpc_id
}