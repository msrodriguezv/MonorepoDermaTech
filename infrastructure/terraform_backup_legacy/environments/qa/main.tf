# infrastructure/terraform/environments/qa/main.tf

# AWS Provider Configuration
provider "aws" {
  region  = "us-east-1"
  profile = "qa-dermatech" # PERFIL REAL: NO CAMBIAR
}

# Local variables for this environment
locals {
  project_name = "dermatech"
  environment  = "qa"
  # AMI ID for Amazon Linux 2023 in us-east-1
  ami_id_us_east_1 = "ami-051f7e7f6c2f40dc1"
}

# --- Module Calls ---

# 1. Create Networking for QA (Ahora con Zona B)
module "networking" {
  source = "../../modules/aws-networking"

  region             = "us-east-1"         # Mantenemos la región base
  project_name       = local.project_name
  environment        = local.environment
  
  # Zona A (EXISTENTE - NO TOCAR EL CIDR)
  vpc_cidr           = "10.0.0.0/16" 
  public_subnet_cidr = "10.0.1.0/24"

  # Zona B (NUEVA - Agregamos un rango nuevo dentro de la VPC)
  public_subnet_cidr_b = "10.0.2.0/24"
}

# 2. Create Gateway and Nodes for QA
module "gateway" {
  source = "../../modules/aws-load-balancer"

  project_name       = local.project_name
  environment        = local.environment
  vpc_id             = module.networking.vpc_id
  ami_id             = local.ami_id_us_east_1
  
  # Zona A (EXISTENTE - Aquí vive la Elastic IP)
  public_subnet_id   = module.networking.public_subnet_id

  # Zona B (NUEVA - Aquí vivirá el nodo de respaldo sin IP fija)
  public_subnet_id_b = module.networking.public_subnet_id_b
}

# --- Final Output ---
output "QA_STATIC_IP" {
  value       = module.gateway.final_public_ip
  description = "Provide this IP to the professor for the QA firewall"
}

output "QA_PUBLIC_DNS" {
  value       = module.gateway.final_public_dns
  description = "The Public DNS required for the configuration"
}