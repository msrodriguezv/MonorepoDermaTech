terraform {
  backend "s3" {
    bucket = "tfstate-qa-dermatech"
    key    = "qa/terraform.tfstate"
    region = "us-east-1"
  }
}

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
  vpc_cidr           = var.qa_cidr            
  public_subnet_cidr = "10.0.1.0/24"
  availability_zone  = "us-east-1a"            
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

  # Fixed Private IP for Internal Network Consistency
  bastion_private_ip  = "10.0.1.59"
  
  # Shielded Elastic IP (Cloudflare) - Existing Allocation ID
  eip_allocation_id   = "eipalloc-04a19075ece27ac49"
}

# ==============================================================================
# 3. INTERCONNECTION LAYER (VPC PEERING REQUESTS)
# Uses injected Variable IDs instead of Data Lookups to enable CI/CD workflows
# ==============================================================================

resource "aws_vpc_peering_connection" "qa_to_events" {
  peer_owner_id = var.events_account_id
  peer_vpc_id   = var.events_vpc_id   # Injected Variable
  vpc_id        = module.networking.vpc_id
  auto_accept   = false
  tags          = { Name = "qa-to-events-peering" }
}

resource "aws_vpc_peering_connection" "qa_to_state" {
  peer_owner_id = var.state_account_id
  peer_vpc_id   = var.state_vpc_id    # Injected Variable
  vpc_id        = module.networking.vpc_id
  auto_accept   = false
  tags          = { Name = "qa-to-state-peering" }
}

resource "aws_vpc_peering_connection" "qa_to_node_a" {
  peer_owner_id = var.node_a_account_id
  peer_vpc_id   = var.node_a_vpc_id   # Injected Variable
  vpc_id        = module.networking.vpc_id
  auto_accept   = false
  tags          = { Name = "qa-to-node-a-peering" }
}

resource "aws_vpc_peering_connection" "qa_to_node_b" {
  peer_owner_id = var.node_b_account_id
  peer_vpc_id   = var.node_b_vpc_id   # Injected Variable
  vpc_id        = module.networking.vpc_id
  auto_accept   = false
  tags          = { Name = "qa-to-node-b-peering" }
}

# ==============================================================================
# 4. ROUTING LAYER (ACCESS TO SPOKE NETWORKS)
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
# 5. OUTPUTS
# ==============================================================================
output "QA_GATEWAY_PUBLIC_IP" {
  value = module.gateway.final_public_ip
}

output "QA_GATEWAY_PRIVATE_IP" {
  value = module.gateway.bastion_private_ip
}

output "QA_VPC_ID" {
  value = module.networking.vpc_id
}