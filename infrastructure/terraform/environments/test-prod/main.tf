# infrastructure/terraform/environments/test-prod/main.tf

# AWS Provider Configuration
provider "aws" {
  region  = "us-east-1"
  profile = "pruebas-prod" # PERFIL DE PRUEBAS
}

# Local variables for this environment
locals {
  project_name = "dermatech"
  environment  = "test-prod" #  Nombre distinto para trazabilidad
  # AMI ID for Amazon Linux 2023 in us-east-1
  ami_id_us_east_1 = "ami-051f7e7f6c2f40dc1"
}

# --- Module Calls ---

# 1. Create Networking for TEST-PROD
module "networking" {
  source = "../../modules/aws-networking"

  region             = "us-east-1"
  project_name       = local.project_name
  environment        = local.environment
  
  # Usamos la misma estructura de red que PROD para simulación exacta
  vpc_cidr           = "172.16.0.0/16" 
  public_subnet_cidr = "172.16.1.0/24"
  
  # Agregamos la Zona B
  public_subnet_cidr_b = "172.16.2.0/24"
}

# 2. Create Gateway and Nodes for TEST-PROD
module "gateway" {
  source = "../../modules/aws-load-balancer"

  project_name       = local.project_name
  environment        = local.environment
  vpc_id             = module.networking.vpc_id
  ami_id             = local.ami_id_us_east_1
  
  # Conexiones a subnets
  public_subnet_id   = module.networking.public_subnet_id
  public_subnet_id_b = module.networking.public_subnet_id_b
}

# --- Final Output ---
output "TEST_PROD_STATIC_IP" {
  value       = module.gateway.final_public_ip
  description = "Static IP generated for the TEST environment"
}

output "TEST_PROD_PUBLIC_DNS" {
  value       = module.gateway.final_public_dns
  description = "Public DNS for the TEST environment"
}