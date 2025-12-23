# infrastructure/terraform/modules/aws-networking/variables.tf

variable "region" {
  description = "AWS Region to deploy resources"
  type        = string
}

variable "project_name" {
  description = "Project name (e.g., dermatech)"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., qa, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
}