# ==============================================================================
# MODULE VARIABLES: AWS NETWORKING
# Context: VPC, Subnets, Routing, and Availability Zones
# ==============================================================================

variable "region" {
  description = "AWS Region for deployment (e.g., us-east-1)"
  type        = string
}

variable "project_name" {
  description = "Project identifier used for resource tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., qa, infra-node-a)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the Public Subnet"
  type        = string
}

variable "availability_zone" {
  description = "Specific Availability Zone for High Availability (e.g., us-east-1a, us-east-1b)"
  type        = string
  default     = "us-east-1a"
}