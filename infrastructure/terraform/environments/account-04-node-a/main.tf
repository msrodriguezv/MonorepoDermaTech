# ==============================================================================
# ENVIRONMENT: NODE A (Application Server 1)
# Purpose: Main application node hosting microservices in High Availability (AZ 1a)
# ==============================================================================
terraform {
  backend "s3" {
    bucket = "tfstate-node-a-dermatech"
    key    = "node-a/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "node-a-dermatech" 
}

# ==============================================================================
# 1. NETWORKING LAYER (AZ: us-east-1a)
# ==============================================================================
module "networking" {
  source             = "../../modules/aws-networking"
  region             = "us-east-1"
  project_name       = "dermatech"
  environment        = "infra-node-a"
  vpc_cidr           = var.node_a_cidr          
  public_subnet_cidr = "10.3.1.0/24"
  availability_zone  = "us-east-1a" 
}

# ==============================================================================
# 2. COMPUTE LAYER (APPLICATION WORKER)
# ==============================================================================
module "compute" {
  source              = "../../modules/aws-compute-app"
  project_name        = "dermatech"
  environment         = "infra-node-a"
  vpc_id              = module.networking.vpc_id
  public_subnet_id    = module.networking.public_subnet_id
  ami_id              = "ami-051f7e7f6c2f40dc1" 
  
  # CONFIGURACIÓN ESPECÍFICA NODO A (High Availability)
  availability_zone   = "us-east-1a"
  private_ip_address  = "10.3.1.10"
  gateway_allowed_ip  = var.qa_bastion_ip
  
  # HARDCODED ALLOCATION ID (BLINDADO)
  eip_allocation_id   = "eipalloc-023185aa6f1f7bafb"
}

# ==============================================================================
# 3. INTERCONNECTION LAYER (AUTOMATED PEERING REQUESTS)
# Uses Injected Variable IDs (Workflow Safe)
# ==============================================================================

# Peering Request towards Events Account (Kafka/RabbitMQ)
resource "aws_vpc_peering_connection" "node_a_to_events" {
  peer_owner_id = var.events_account_id
  peer_vpc_id   = var.events_vpc_id   # Variable injected by Workflow
  vpc_id        = module.networking.vpc_id
  auto_accept   = false
  tags          = { Name = "node-a-to-events-peering" }
}

# Peering Request towards State Account (Redis/Metrics)
resource "aws_vpc_peering_connection" "node_a_to_state" {
  peer_owner_id = var.state_account_id
  peer_vpc_id   = var.state_vpc_id    # Variable injected by Workflow
  vpc_id        = module.networking.vpc_id
  auto_accept   = false
  tags          = { Name = "node-a-to-state-peering" }
}

# ==============================================================================
# 4. ROUTING LAYER (CROSS-ACCOUNT TRAFFIC)
# ==============================================================================

# Route to Events Subnet (10.1.0.0/16)
resource "aws_route" "route_to_events" {
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.events_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.node_a_to_events.id
}

# Route to State Subnet (10.2.0.0/16)
resource "aws_route" "route_to_state" {
  route_table_id            = module.networking.public_route_table_id
  destination_cidr_block    = var.state_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.node_a_to_state.id
}

# ==============================================================================
# 5. OUTPUTS
# ==============================================================================
output "NODE_A_PUBLIC_IP" { 
  value = module.compute.public_ip 
}

output "NODE_A_PRIVATE_IP" { 
  value = "10.3.1.10" 
}

# Output needed for QA (if QA is deployed after)
output "vpc_id" {
  value = module.networking.vpc_id
}