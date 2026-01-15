provider "aws" {
  region  = "us-east-1"
  profile = "node-a-dermatech" 
}

# ==============================================================================
# 1. NETWORKING LAYER
# ==============================================================================
module "networking" {
  source             = "../../modules/aws-networking"
  region             = "us-east-1"
  project_name       = "dermatech"
  environment        = "infra-node-a"
  vpc_cidr           = var.node_a_cidr
  public_subnet_cidr = "10.3.1.0/24"
  # Hardcoded AZ for Node A to ensure physical separation
  availability_zone  = "us-east-1a" 
}

# ==============================================================================
# 2. AUTOMATIC DISCOVERY LAYER (DATA SOURCES)
# ==============================================================================

# Automatically discover Events VPC ID after its creation
data "aws_vpc" "events_discovery" {
  filter {
    name   = "tag:Name"
    values = ["dermatech-infra-events-vpc"]
  }
}

# Automatically discover State VPC ID after its creation
data "aws_vpc" "state_discovery" {
  filter {
    name   = "tag:Name"
    values = ["dermatech-infra-state-vpc"]
  }
}

# ==============================================================================
# 3. COMPUTE LAYER (APP NODE)
# ==============================================================================
module "compute" {
  source             = "../../modules/aws-compute-app"
  project_name       = "dermatech"
  environment        = "infra-node-a"
  vpc_id             = module.networking.vpc_id
  public_subnet_id   = module.networking.public_subnet_id
  ami_id             = "ami-051f7e7f6c2f40dc1" 
  private_ip_address = "10.3.1.10"
  gateway_allowed_ip = var.qa_bastion_ip
}

# ==============================================================================
# 4. INTERCONNECTION LAYER (AUTOMATED PEERING)
# ==============================================================================

resource "aws_vpc_peering_connection" "node_a_to_events" {
  peer_owner_id = var.events_account_id
  peer_vpc_id   = data.aws_vpc.events_discovery.id # Resolved automatically
  vpc_id        = module.networking.vpc_id
  auto_accept   = false
  tags          = { Name = "node-a-to-events-peering" }
}

resource "aws_vpc_peering_connection" "node_a_to_state" {
  peer_owner_id = var.state_account_id
  peer_vpc_id   = data.aws_vpc.state_discovery.id  # Resolved automatically
  vpc_id        = module.networking.vpc_id
  auto_accept   = false
  tags          = { Name = "node-a-to-state-peering" }
}

# ==============================================================================
# 5. ROUTING LAYER
# ==============================================================================

resource "aws_route" "route_to_events" {
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.events_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.node_a_to_events.id
}

resource "aws_route" "route_to_state" {
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.state_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.node_a_to_state.id
}

# ==============================================================================
# 6. OUTPUTS
# ==============================================================================
output "NODE_A_PUBLIC_IP" { value = module.compute.public_ip }
output "NODE_A_PRIVATE_IP" { value = "10.3.1.10" }