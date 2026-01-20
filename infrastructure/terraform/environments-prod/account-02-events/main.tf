terraform {
  backend "s3" {
    bucket = "tfstate-prod-events-dermatech"
    key    = "events/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "prod-events-dermatech" 
}

# ==============================================================================
# 1. NETWORKING LAYER
# Context: VPC Creation and Subnetting
# ==============================================================================
module "networking" {
  source             = "../../modules/aws-networking"
  region             = "us-east-1"
  project_name       = "dermatech"
  environment        = "prod-events"
  vpc_cidr           = var.events_cidr
  public_subnet_cidr = "10.1.1.0/24"
  availability_zone  = "us-east-1a"
}

# ==============================================================================
# 2. COMPUTE LAYER (MESSAGING SERVER)
# Context: Kafka, RabbitMQ, Zookeeper Host
# ==============================================================================
module "compute" {
  source              = "../../modules/aws-compute-events" 
   
  project_name        = "dermatech"
  environment         = "prod-events"
  vpc_id              = module.networking.vpc_id
  public_subnet_id    = module.networking.public_subnet_id
  ami_id              = "ami-051f7e7f6c2f40dc1" 
   
  # PERSISTENCE & NETWORK FIXED VALUES
  region              = "us-east-1"
  availability_zone   = "us-east-1a"
  private_ip_address  = "10.1.1.50"
   
  # HARDCODED ALLOCATION ID (PROD)
  # Critical: Prevents terraform from creating a new IP. Uses the manual one.
  eip_allocation_id   = "eipalloc-02820f531a4524871"

  # SECURITY
  # Note: Access rules are defined in the module SG, referring to these CIDRs
  gateway_allowed_ip  = var.prod_bastion_ip 
  app_nodes_ips       = [var.node_a_cidr, var.node_b_cidr, var.state_cidr]
}