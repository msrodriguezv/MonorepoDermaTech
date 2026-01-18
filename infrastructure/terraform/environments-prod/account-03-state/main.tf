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
  vpc_cidr           = var.state_cidr        # 10.2.0.0/16
  public_subnet_cidr = "10.2.1.0/24"
  # Consistent AZ for storage and compute alignment
  availability_zone  = "us-east-1a"
}

# ==============================================================================
# 2. COMPUTE LAYER (DATABASE SERVER)
# ==============================================================================
module "compute" {
  source             = "../../modules/aws-compute-state"
  project_name       = "dermatech"
  environment        = "infra-state"
  vpc_id             = module.networking.vpc_id
  public_subnet_id   = module.networking.public_subnet_id
  ami_id             = "ami-051f7e7f6c2f40dc1" 
  private_ip_address = "10.2.1.100"
  
  # Pass region and AZ for EBS volume attachment
  region             = "us-east-1"
  availability_zone  = "us-east-1a"

  # SECURITY: Access via Peering from QA and App Nodes
  gateway_allowed_ip = var.qa_bastion_ip 
  app_nodes_ips      = [var.node_a_cidr, var.node_b_cidr]
}

# ==============================================================================
# 3. INTERCONNECTION LAYER (AUTO-DISCOVERY ACCEPTERS)
# Purpose: Detect and accept peering requests from Peer Accounts automatically.
# ==============================================================================

# Accept from QA Hub
data "aws_vpc_peering_connection" "qa_request" {
  peer_owner_id = var.qa_account_id
  peer_vpc_id   = module.networking.vpc_id
  status        = "pending-acceptance"
}

resource "aws_vpc_peering_connection_accepter" "qa_accepter" {
  vpc_peering_connection_id = data.aws_vpc_peering_connection.qa_request.id
  auto_accept               = true
  tags = { 
    Name = "state-accept-qa" 
    Side = "Accepter"
  }
}

# Accept from Node A
data "aws_vpc_peering_connection" "node_a_request" {
  peer_owner_id = var.node_a_account_id
  peer_vpc_id   = module.networking.vpc_id
  status        = "pending-acceptance"
}

resource "aws_vpc_peering_connection_accepter" "node_a_accepter" {
  vpc_peering_connection_id = data.aws_vpc_peering_connection.node_a_request.id
  auto_accept               = true
  tags = { 
    Name = "state-accept-node-a" 
    Side = "Accepter"
  }
}

# Accept from Node B
data "aws_vpc_peering_connection" "node_b_request" {
  peer_owner_id = var.node_b_account_id
  peer_vpc_id   = module.networking.vpc_id
  status        = "pending-acceptance"
}

resource "aws_vpc_peering_connection_accepter" "node_b_accepter" {
  vpc_peering_connection_id = data.aws_vpc_peering_connection.node_b_request.id
  auto_accept               = true
  tags = { 
    Name = "state-accept-node-b" 
    Side = "Accepter"
  }
}

# ==============================================================================
# 4. ROUTING LAYER (RETURN ROUTES)
# ==============================================================================

resource "aws_route" "route_back_to_qa" {
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.qa_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.qa_accepter.id
}

resource "aws_route" "route_back_to_node_a" {
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.node_a_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.node_a_accepter.id
}

resource "aws_route" "route_back_to_node_b" {
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.node_b_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.node_b_accepter.id
}

# ==============================================================================
# 5. OUTPUTS
# ==============================================================================
output "STATE_PUBLIC_IP" { 
  value = module.compute.public_ip 
}

output "STATE_PRIVATE_IP" {
  value       = "10.2.1.100"
  description = "Internal IP for Redis/Monitoring"
}