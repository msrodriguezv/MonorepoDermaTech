provider "aws" {
  region  = "us-east-1"
  profile = "node-b-dermatech" 
}

# ==============================================================================
# 1. NETWORKING LAYER (High Availability)
# ==============================================================================
module "networking" {
  source             = "../../modules/aws-networking"
  region             = "us-east-1"
  project_name       = "dermatech"
  environment        = "infra-node-b"
  vpc_cidr           = var.node_b_cidr
  public_subnet_cidr = "10.4.1.0/24"
  # Hardcoded AZ for Node B to ensure physical separation from Node A
  availability_zone  = "us-east-1b" 
}

# ==============================================================================
# 2. AUTOMATIC DISCOVERY LAYER (DATA SOURCES)
# ==============================================================================

data "aws_vpc" "events_discovery" {
  filter {
    name   = "tag:Name"
    values = ["dermatech-infra-events-vpc"]
  }
}

data "aws_vpc" "state_discovery" {
  filter {
    name   = "tag:Name"
    values = ["dermatech-infra-state-vpc"]
  }
}

# ==============================================================================
# 3. COMPUTE LAYER (APP NODE B)
# ==============================================================================
module "compute" {
  source             = "../../modules/aws-compute-app"
  project_name       = "dermatech"
  environment        = "infra-node-b"
  vpc_id             = module.networking.vpc_id
  public_subnet_id   = module.networking.public_subnet_id
  ami_id             = "ami-051f7e7f6c2f40dc1" 
  private_ip_address = "10.4.1.10"
  gateway_allowed_ip = var.qa_bastion_ip
}

# ==============================================================================
# 4. INTERCONNECTION LAYER (AUTOMATED PEERING)
# ==============================================================================

resource "aws_vpc_peering_connection" "node_b_to_events" {
  peer_owner_id = var.events_account_id
  peer_vpc_id   = data.aws_vpc.events_discovery.id
  vpc_id        = module.networking.vpc_id
  auto_accept   = false
  tags          = { Name = "node-b-to-events-peering" }
}

resource "aws_vpc_peering_connection" "node_b_to_state" {
  peer_owner_id = var.state_account_id
  peer_vpc_id   = data.aws_vpc.state_discovery.id
  vpc_id        = module.networking.vpc_id
  auto_accept   = false
  tags          = { Name = "node-b-to-state-peering" }
}

# ==============================================================================
# 5. ROUTING LAYER
# ==============================================================================

resource "aws_route" "route_to_events" {
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.events_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.node_b_to_events.id
}

resource "aws_route" "route_to_state" {
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.state_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.node_b_to_state.id
}

# ==============================================================================
# 6. OUTPUTS
# ==============================================================================
output "NODE_B_PUBLIC_IP" { value = module.compute.public_ip }
output "NODE_B_PRIVATE_IP" { value = "10.4.1.10" }