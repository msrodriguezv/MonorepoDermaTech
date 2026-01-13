provider "aws" {
  region  = "us-east-1"
  profile = "qa-dermatech" 
}

locals {
  project_name = "dermatech"
  environment  = "qa"
  ami_id       = "ami-051f7e7f6c2f40dc1" # Amazon Linux 2023
}

module "networking" {
  source             = "../../modules/aws-networking"
  region             = "us-east-1"
  project_name       = local.project_name
  environment        = local.environment
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidr = "10.0.1.0/24"
}

module "gateway" {
  source           = "../../modules/aws-gateway-node"
  project_name     = local.project_name
  environment      = local.environment
  vpc_id           = module.networking.vpc_id
  ami_id           = local.ami_id
  public_subnet_id = module.networking.public_subnet_id
}

output "QA_GATEWAY_IP" {
  value = module.gateway.final_public_ip
}