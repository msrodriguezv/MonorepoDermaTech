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
# Context: VPC Creation for App Node A
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
# Context: NestJS & Flutter Host
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