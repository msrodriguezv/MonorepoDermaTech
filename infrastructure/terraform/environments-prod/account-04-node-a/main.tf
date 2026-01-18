# ==============================================================================
# ENVIRONMENT: NODE A (Application Server 1)
# Purpose: Main application node hosting microservices in High Availability
# ==============================================================================

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
  vpc_cidr           = var.node_a_cidr         # 10.3.0.0/16
  public_subnet_cidr = "10.3.1.0/24"
  # Hardcoded AZ for Node A to ensure physical separation
  availability_zone  = "us-east-1a" 
}

# ==============================================================================
# 2. AUTOMATIC DISCOVERY LAYER (DATA SOURCES)
# Purpose: Fetch remote VPC IDs dynamically to enable zero-manual deployment.
# ==============================================================================

# Automatically discover Events VPC ID (Messaging)
data "aws_vpc" "events_discovery" {
  filter {
    name   = "tag:Name"
    values = ["dermatech-infra-events-vpc"]
  }
}

# Automatically discover State VPC ID (Persistence/Database)
data "aws_vpc" "state_discovery" {
  filter {
    name   = "tag:Name"
    values = ["dermatech-infra-state-vpc"]
  }
}

# ==============================================================================
# 3. COMPUTE LAYER (APPLICATION WORKER)
# ==============================================================================
module "compute" {
  source             = "../../modules/aws-compute-app"
  project_name       = "dermatech"
  environment        = "infra-node-a"
  vpc_id             = module.networking.vpc_id
  public_subnet_id   = module.networking.public_subnet_id
  ami_id             = "ami-051f7e7f6c2f40dc1" 
  private_ip_address = "10.3.1.10"
  gateway_allowed_ip = var.qa_bastion_ip # Security restricted to Bastion Tunnel
}

# ==============================================================================
# 4. INTERCONNECTION LAYER (AUTOMATED PEERING REQUESTS)
# ==============================================================================

# Peering Request towards Events Account (Kafka/RabbitMQ)
resource "aws_vpc_peering_connection" "node_a_to_events" {
  peer_owner_id = var.events_account_id
  peer_vpc_id   = data.aws_vpc.events_discovery.id
  vpc_id        = module.networking.vpc_id
  auto_accept   = false
  tags          = { Name = "node-a-to-events-peering" }
}

# Peering Request towards State Account (Redis/Metrics)
resource "aws_vpc_peering_connection" "node_a_to_state" {
  peer_owner_id = var.state_account_id
  peer_vpc_id   = data.aws_vpc.state_discovery.id
  vpc_id        = module.networking.vpc_id
  auto_accept   = false
  tags          = { Name = "node-a-to-state-peering" }
}

# ==============================================================================
# 5. ROUTING LAYER (CROSS-ACCOUNT TRAFFIC)
# ==============================================================================

# Route to Events Subnet (10.1.0.0/16) via Peering Tunnel
resource "aws_route" "route_to_events" {
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.events_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.node_a_to_events.id
}

# Route to State Subnet (10.2.0.0/16) via Peering Tunnel
resource "aws_route" "route_to_state" {
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.state_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.node_a_to_state.id
}

# ==============================================================================
# 6. OUTPUTS
# ==============================================================================
output "NODE_A_PUBLIC_IP" { 
  description = "Elastic IP of Node A"
  value       = module.compute.public_ip 
}

output "NODE_A_PRIVATE_IP" { 
  description = "Internal IP"
  value       = "10.3.1.10" 
}