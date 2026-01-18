# ==============================================================================
# ENVIRONMENT: NODE B (Application Server 2)
# Purpose: High Availability Replica (AZ 1b)
# ==============================================================================
terraform {
  backend "s3" {
    bucket = "tfstate-node-b-dermatech"
    key    = "node-b/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "node-b-dermatech" 
}

# ==============================================================================
# 1. NETWORKING LAYER (AZ: us-east-1b)
# Context: VPC Creation for App Node B (HA Zone)
# ==============================================================================
module "networking" {
  source             = "../../modules/aws-networking"
  region             = "us-east-1"
  project_name       = "dermatech"
  environment        = "infra-node-b"
  vpc_cidr           = var.node_b_cidr          
  public_subnet_cidr = "10.4.1.0/24"
  availability_zone  = "us-east-1b" # High Availability Zone
}

# ==============================================================================
# 2. COMPUTE LAYER (APPLICATION WORKER)
# Context: NestJS & Flutter Host Replica
# ==============================================================================
module "compute" {
  source              = "../../modules/aws-compute-app"
  project_name        = "dermatech"
  environment         = "infra-node-b"
  vpc_id              = module.networking.vpc_id
  public_subnet_id    = module.networking.public_subnet_id
  ami_id              = "ami-051f7e7f6c2f40dc1" 
  
  # CONFIGURACIÓN ESPECÍFICA NODO B
  availability_zone   = "us-east-1b" 
  private_ip_address  = "10.4.1.10"
  gateway_allowed_ip  = var.qa_bastion_ip
  
  # HARDCODED ALLOCATION ID (BLINDADO)
  eip_allocation_id   = "eipalloc-0f602e180348c4ad9" 
}