# ==============================================================================
# ENVIRONMENT: PROD NODE B (Application Server 2)
# Purpose: High Availability Replica (AZ 1b)
# Specs: Injected into PROD Hub via VPC Peering for master orchestration.
# ==============================================================================
terraform {
  backend "s3" {
    bucket = "tfstate-prod-node-b-dermatech"
    key    = "node-b/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "prod-node-b-dermatech" 
}

# ==============================================================================
# 1. NETWORKING LAYER (AZ: us-east-1b)
# Context: VPC Creation for App Node B (HA Zone PROD)
# ==============================================================================
module "networking" {
  source             = "../../modules/aws-networking"
  region             = "us-east-1"
  project_name       = "dermatech"
  environment        = "prod-node-b"
  vpc_cidr           = var.node_b_cidr           
  public_subnet_cidr = "10.4.1.0/24"
  availability_zone  = "us-east-1b" # High Availability Zone
}

# ==============================================================================
# 2. COMPUTE LAYER (APPLICATION WORKER)
# Context: NestJS & Flutter Host Replica (PROD)
# ==============================================================================
module "compute" {
  source              = "../../modules/aws-compute-app"
  project_name        = "dermatech"
  environment         = "prod-node-b"
  vpc_id              = module.networking.vpc_id
  public_subnet_id    = module.networking.public_subnet_id
  ami_id              = "ami-051f7e7f6c2f40dc1" 
   
  # HIGH AVAILABILITY CONFIGURATION: NODE B
  availability_zone   = "us-east-1b" 
  private_ip_address  = "10.4.1.10"
   
  # SECURITY: Allow traffic from the entire PROD VPC (ALB range)
  # Essential for cross-account load balancing and internal microservices health checks.
  gateway_allowed_ip  = var.prod_cidr
   
  # HARDCODED ALLOCATION ID (PROD SHIELDED ELASTIC IP)
  eip_allocation_id   = "eipalloc-08d5bb1528dc71ec7" 
}