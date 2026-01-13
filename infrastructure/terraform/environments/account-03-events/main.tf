provider "aws" {
  region  = "us-east-1"
  profile = "events-dermatech" 
}

module "networking" {
  source             = "../../modules/aws-networking"
  region             = "us-east-1"
  project_name       = "dermatech"
  environment        = "infra-events"
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidr = "10.0.1.0/24"
}

module "compute" {
  source           = "../../modules/aws-compute-node"
  project_name     = "dermatech"
  environment      = "infra-events"
  vpc_id           = module.networking.vpc_id
  ami_id           = "ami-051f7e7f6c2f40dc1"
  public_subnet_id = module.networking.public_subnet_id
}

output "EVENTS_IP" { value = module.compute.public_ip }