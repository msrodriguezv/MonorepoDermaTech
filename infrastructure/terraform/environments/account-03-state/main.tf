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
# Context: VPC for State Persistence & Monitoring
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
# Context: Redis, Prometheus, Grafana Host
# ==============================================================================
module "compute" {
  source              = "../../modules/aws-compute-state" 
  
  project_name        = "dermatech"
  environment         = "infra-state"
  vpc_id              = module.networking.vpc_id
  public_subnet_id    = module.networking.public_subnet_id
  ami_id              = "ami-051f7e7f6c2f40dc1" 
  
  # PERSISTENCE & NETWORK FIXED VALUES
  region              = "us-east-1"
  availability_zone   = "us-east-1a"
  private_ip_address  = "10.2.1.100"
  
  # HARDCODED ALLOCATION ID (BLINDADO)
  eip_allocation_id   = "eipalloc-06cab0c77784902e7" 

  # SECURITY
  # Note: Access rules defined in module SG
  gateway_allowed_ip  = var.qa_bastion_ip 
  # Allow access from App Nodes AND Events (Critical for Prometheus scraping Kafka)
  app_nodes_ips       = [var.node_a_cidr, var.node_b_cidr, var.events_cidr]
}