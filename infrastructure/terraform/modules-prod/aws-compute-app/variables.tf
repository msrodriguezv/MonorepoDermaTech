# ==============================================================================
# MODULE VARIABLES: AWS COMPUTE APP
# Context: Application Workers (Node A & Node B)
# ==============================================================================

variable "region" {
  description = "Target AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "ID of the VPC where the Node will be deployed"
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the Public Subnet for network interface attachment"
  type        = string
}

variable "project_name" {
  description = "Project identifier tag"
  type        = string
}

variable "environment" {
  description = "Deployment environment tag"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "private_ip_address" {
  description = "Static Private IP to assign to the instance"
  type        = string
}

variable "gateway_allowed_ip" {
  description = "The Elastic IP (CIDR) of the Gateway/Bastion (QA or PROD)"
  type        = string
}

# --- High Availability Configuration ---
variable "availability_zone" {
  description = "Availability Zone for the instance (e.g., us-east-1a or us-east-1b)"
  type        = string
}

variable "eip_allocation_id" {
  description = "The AWS Allocation ID (eipalloc-...) of the pre-existing IP"
  type        = string
}