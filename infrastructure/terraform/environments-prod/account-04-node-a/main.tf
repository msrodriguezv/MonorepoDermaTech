# ==============================================================================
# ENVIRONMENT: PROD NODE A (Application Server 1)
# Purpose: Main application node hosting microservices in High Availability (AZ 1a)
# Specs: Injected into PROD Hub via VPC Peering for master orchestration.
# ==============================================================================
terraform {
  backend "s3" {
    bucket = "tfstate-prod-node-a-dermatech"
    key    = "node-a/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "prod-node-a-dermatech" 
}

# ==============================================================================
# 1. NETWORKING LAYER (AZ: us-east-1a)
# Context: VPC Creation for App Node A (PROD)
# ==============================================================================
module "networking" {
  source             = "../../modules/aws-networking"
  region             = "us-east-1"
  project_name       = "dermatech"
  environment        = "prod-node-a"
  vpc_cidr           = var.node_a_cidr           
  public_subnet_cidr = "10.3.1.0/24"
  availability_zone  = "us-east-1a" 
}

# ==============================================================================
# 2. COMPUTE LAYER (APPLICATION WORKER)
# Context: NestJS Microservices & Flutter Web Host (PROD)
# ==============================================================================
module "compute" {
  source              = "../../modules/aws-compute-app"
  project_name        = "dermatech"
  environment         = "prod-node-a"
  vpc_id              = module.networking.vpc_id
  public_subnet_id    = module.networking.public_subnet_id
  ami_id              = "ami-051f7e7f6c2f40dc1" 
   
  # HIGH AVAILABILITY CONFIGURATION: NODE A
  availability_zone   = "us-east-1a"
  private_ip_address  = "10.3.1.10"
   
  # SECURITY: Allow traffic from the entire PROD VPC (ALB range)
  # This enables the Load Balancer to perform health checks and route traffic.
  gateway_allowed_ip  = var.prod_cidr
   
  # HARDCODED ALLOCATION ID (PROD SHIELDED ELASTIC IP)
  eip_allocation_id   = "eipalloc-0d994196393ba1d5b"
}