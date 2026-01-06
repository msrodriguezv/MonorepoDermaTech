# infrastructure/terraform/modules/aws-load-balancer/variables.tf

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the gateway will be deployed"
  type        = string
}

variable "public_subnet_id" {
  description = "Public Subnet ID for the Elastic IP association"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "public_subnet_id_b" {
  description = "Public Subnet ID for the Node B"
  type        = string
}