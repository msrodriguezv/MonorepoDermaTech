# infrastructure/terraform/environments/prod/main.tf

# AWS Provider Configuration
provider "aws" {
  region  = "us-east-1"
  profile = "prod-dermatech" # MUST match your local AWS credentials profile
}

# Local variables for this environment
locals {
  project_name = "dermatech"
  environment  = "prod"
  # AMI ID for Amazon Linux 2023 in us-east-1
  ami_id_us_east_1 = "ami-051f7e7f6c2f40dc1"
}

# --- Module Calls ---

# 1. Create Networking for PROD
module "networking" {
  source = "../../modules/aws-networking"

  region             = "us-east-1"
  project_name       = local.project_name
  environment        = local.environment
  vpc_cidr           = "172.16.0.0/16" # Different CIDR for PROD
  public_subnet_cidr = "172.16.1.0/24"
}

# 2. Create Gateway and Static IP for PROD
module "gateway" {
  source = "../../modules/aws-load-balancer"

  project_name     = local.project_name
  environment      = local.environment
  vpc_id           = module.networking.vpc_id
  public_subnet_id = module.networking.public_subnet_id
  ami_id           = local.ami_id_us_east_1
}

# --- Final Output ---
output "PROD_STATIC_IP" {
  value       = module.gateway.final_public_ip
  description = "Provide this IP to the professor for the PROD firewall"
}

output "PROD_PUBLIC_DNS" {
  value       = module.gateway.final_public_dns
  description = "The Public DNS required for the configuration"
}