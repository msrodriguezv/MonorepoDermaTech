# ==============================================================================
# ENVIRONMENT: NODE B (Application Server 2)
# Purpose: High Availability Replica (AZ 1b)
# ==============================================================================
terraform {
  backend "s3" {
    bucket = "tfstate-node-b-dermatech"
    key    = "node-b/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "node-b-dermatech" 
}

locals {
  # Conditional flag: only create peerings if VPC IDs are provided
  create_peerings = (
    var.events_vpc_id != "" &&
    var.state_vpc_id != ""
  )
}

# ==============================================================================
# 1. NETWORKING LAYER (AZ: us-east-1b)
# ==============================================================================
module "networking" {
  source             = "../../modules/aws-networking"
  region             = "us-east-1"
  project_name       = "dermatech"
  environment        = "infra-node-b"
  vpc_cidr           = var.node_b_cidr          
  public_subnet_cidr = "10.4.1.0/24"
  availability_zone  = "us-east-1b" # <--- ALTA DISPONIBILIDAD (Zona B)
}

# ==============================================================================
# 2. COMPUTE LAYER (APPLICATION WORKER)
# ==============================================================================
module "compute" {
  source              = "../../modules/aws-compute-app"
  project_name        = "dermatech"
  environment         = "infra-node-b"
  vpc_id              = module.networking.vpc_id
  public_subnet_id    = module.networking.public_subnet_id
  ami_id              = "ami-051f7e7f6c2f40dc1" 
  
  # CONFIGURACIÓN ESPECÍFICA NODO B
  availability_zone   = "us-east-1b" # <--- ZONA B
  private_ip_address  = "10.4.1.10"
  gateway_allowed_ip  = var.qa_bastion_ip
  
  # HARDCODED ALLOCATION ID (BLINDADO)
  # Asegúrate de que este ID sea el correcto para el Node B
  eip_allocation_id   = "eipalloc-00966a34584282e70" 
}

# ==============================================================================
# 3. INTERCONNECTION LAYER (AUTOMATED PEERING REQUESTS)
# CRITICAL: Only created when VPC IDs are provided (deploy mode)
# ==============================================================================

resource "aws_vpc_peering_connection" "node_b_to_events" {
  count = local.create_peerings ? 1 : 0
  
  peer_owner_id = var.events_account_id
  peer_vpc_id   = var.events_vpc_id 
  vpc_id        = module.networking.vpc_id
  auto_accept   = false
  tags          = { Name = "node-b-to-events-peering" }
}

resource "aws_vpc_peering_connection" "node_b_to_state" {
  count = local.create_peerings ? 1 : 0
  
  peer_owner_id = var.state_account_id
  peer_vpc_id   = var.state_vpc_id 
  vpc_id        = module.networking.vpc_id
  auto_accept   = false
  tags          = { Name = "node-b-to-state-peering" }
}

# ==============================================================================
# 4. ROUTING LAYER
# Routes only created when peerings exist
# ==============================================================================

resource "aws_route" "route_to_events" {
  count = local.create_peerings ? 1 : 0
  
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.events_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.node_b_to_events[0].id
}

resource "aws_route" "route_to_state" {
  count = local.create_peerings ? 1 : 0
  
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.state_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.node_b_to_state[0].id
}

# ==============================================================================
# 5. OUTPUTS
# ==============================================================================
output "NODE_B_PUBLIC_IP" { 
  value = module.compute.public_ip 
}

output "NODE_B_PRIVATE_IP" { 
  value = "10.4.1.10" 
}

output "vpc_id" {
  value = module.networking.vpc_id
}