terraform {
  backend "s3" {
    bucket = "tfstate-state-dermatech"
    key    = "state/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "state-dermatech" 
}

# ==============================================================================
# 1. NETWORKING LAYER
# ==============================================================================
module "networking" {
  source             = "../../modules/aws-networking"
  region             = "us-east-1"
  project_name       = "dermatech"
  environment        = "infra-state"
  vpc_cidr           = var.state_cidr
  public_subnet_cidr = "10.2.1.0/24"
  availability_zone  = "us-east-1a"
}

# ==============================================================================
# 2. COMPUTE LAYER (DATABASE & MONITORING SERVER)
# ==============================================================================
module "compute" {
  source              = "../../modules/aws-compute-state"
  
  project_name        = "dermatech"
  environment         = "infra-state"
  vpc_id              = module.networking.vpc_id
  public_subnet_id    = module.networking.public_subnet_id
  ami_id              = "ami-051f7e7f6c2f40dc1" 
  
  # PERSISTENCE & NETWORK
  region              = "us-east-1"
  availability_zone   = "us-east-1a"
  private_ip_address  = "10.2.1.100"
  
  # HARDCODED ALLOCATION ID (BLINDADO)
  eip_allocation_id   = "eipalloc-06cab0c77784902e7" 

  # SECURITY
  gateway_allowed_ip  = var.qa_bastion_ip 
  app_nodes_ips       = [var.node_a_cidr, var.node_b_cidr]
}

# ==============================================================================
# 3. INTERCONNECTION LAYER (AUTO-ACCEPTERS)
# Only runs if enable_peering_acceptance is TRUE (Workflow Step 3)
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
  tags                      = { Name = "state-accept-qa", Side = "Accepter" }
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
  tags                      = { Name = "state-accept-node-a", Side = "Accepter" }
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
  tags                      = { Name = "state-accept-node-b", Side = "Accepter" }
}

# ==============================================================================
# 4. ROUTING LAYER (RETURN TRAFFIC)
# Only created when Peering is Accepted
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
output "STATE_PUBLIC_IP" { 
  value = module.compute.public_ip 
}

output "STATE_PRIVATE_IP" {
  value = "10.2.1.100"
}

# Required for Workflow injection
output "vpc_id" {
  value = module.networking.vpc_id
}