terraform {
  backend "s3" {
    bucket = "tfstate-events-dermatech"
    key    = "events/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "events-dermatech" 
}

# ==============================================================================
# 1. NETWORKING LAYER
# ==============================================================================
module "networking" {
  source             = "../../modules/aws-networking"
  region             = "us-east-1"
  project_name       = "dermatech"
  environment        = "infra-events"
  vpc_cidr           = var.events_cidr
  public_subnet_cidr = "10.1.1.0/24"
  availability_zone  = "us-east-1a"
}

# ==============================================================================
# 2. COMPUTE LAYER (MESSAGING SERVER)
# ==============================================================================
module "compute" {
  source              = "../../modules/aws-compute-events" 
  
  project_name        = "dermatech"
  environment         = "infra-events"
  vpc_id              = module.networking.vpc_id
  public_subnet_id    = module.networking.public_subnet_id
  ami_id              = "ami-051f7e7f6c2f40dc1" 
  
  # PERSISTENCE & NETWORK FIXED VALUES
  region              = "us-east-1"
  availability_zone   = "us-east-1a"
  private_ip_address  = "10.1.1.50"
  
  # HARDCODED ALLOCATION ID (BLINDADO)
  eip_allocation_id   = "eipalloc-0e0551efd3c2b669f"

  # SECURITY
  gateway_allowed_ip  = var.qa_bastion_ip 
  app_nodes_ips       = [var.node_a_cidr, var.node_b_cidr]
}

# ==============================================================================
# 3. INTERCONNECTION LAYER (AUTO-ACCEPTERS)
# CRITICAL: This block only runs if enable_peering_acceptance is TRUE
# This prevents the "Resource not found" error during the first deployment run.
# ==============================================================================

# --- Accept from QA ---
data "aws_vpc_peering_connection" "qa_request" {
  count           = var.enable_peering_acceptance ? 1 : 0
  peer_owner_id   = var.qa_account_id
  peer_vpc_id     = module.networking.vpc_id
  status          = "pending-acceptance"
}
resource "aws_vpc_peering_connection_accepter" "qa_accepter" {
  count                     = var.enable_peering_acceptance ? 1 : 0
  vpc_peering_connection_id = data.aws_vpc_peering_connection.qa_request[0].id
  auto_accept               = true
  tags                      = { Name = "events-accept-qa", Side = "Accepter" }
}

# --- Accept from Node A ---
data "aws_vpc_peering_connection" "node_a_request" {
  count           = var.enable_peering_acceptance ? 1 : 0
  peer_owner_id   = var.node_a_account_id
  peer_vpc_id     = module.networking.vpc_id
  status          = "pending-acceptance"
}
resource "aws_vpc_peering_connection_accepter" "node_a_accepter" {
  count                     = var.enable_peering_acceptance ? 1 : 0
  vpc_peering_connection_id = data.aws_vpc_peering_connection.node_a_request[0].id
  auto_accept               = true
  tags                      = { Name = "events-accept-node-a", Side = "Accepter" }
}

# --- Accept from Node B ---
data "aws_vpc_peering_connection" "node_b_request" {
  count           = var.enable_peering_acceptance ? 1 : 0
  peer_owner_id   = var.node_b_account_id
  peer_vpc_id     = module.networking.vpc_id
  status          = "pending-acceptance"
}
resource "aws_vpc_peering_connection_accepter" "node_b_accepter" {
  count                     = var.enable_peering_acceptance ? 1 : 0
  vpc_peering_connection_id = data.aws_vpc_peering_connection.node_b_request[0].id
  auto_accept               = true
  tags                      = { Name = "events-accept-node-b", Side = "Accepter" }
}

# ==============================================================================
# 4. ROUTING LAYER (RETURN TRAFFIC)
# Routes are created only when peering is accepted
# ==============================================================================

resource "aws_route" "route_back_to_qa" {
  count                     = var.enable_peering_acceptance ? 1 : 0
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.qa_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.qa_accepter[0].id
}

resource "aws_route" "route_back_to_node_a" {
  count                     = var.enable_peering_acceptance ? 1 : 0
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.node_a_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.node_a_accepter[0].id
}

resource "aws_route" "route_back_to_node_b" {
  count                     = var.enable_peering_acceptance ? 1 : 0
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.node_b_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.node_b_accepter[0].id
}

# ==============================================================================
# 5. OUTPUTS
# ==============================================================================
output "EVENTS_PUBLIC_IP" { 
  value = module.compute.public_ip 
}

output "EVENTS_PRIVATE_IP" {
  value = "10.1.1.50"
}

# Output needed for Workflows
output "vpc_id" {
  value = module.networking.vpc_id
}