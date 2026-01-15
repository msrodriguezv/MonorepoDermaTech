# ==============================================================================
# MODULE VARIABLES
# Context: AWS Compute App (Worker Nodes)
# Purpose: Define input parameters for reusable Node configuration
# ==============================================================================

# ------------------------------------------------------------------------------
# AWS & NETWORK CONFIGURATION
# ------------------------------------------------------------------------------
variable "region" {
  description = "Target AWS Region for deployment"
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

# ------------------------------------------------------------------------------
# PROJECT METADATA
# ------------------------------------------------------------------------------
variable "project_name" {
  description = "Project identifier (e.g., dermatech)"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., qa, prod)"
  type        = string
}

# ------------------------------------------------------------------------------
# COMPUTE CONFIGURATION
# ------------------------------------------------------------------------------
variable "ami_id" {
  description = "AMI ID for the EC2 instance (Amazon Linux 2023 recommended)"
  type        = string
}

variable "private_ip_address" {
  description = "Static Private IP to assign to the instance (e.g., 10.3.1.10). Essential for internal DNS stability."
  type        = string
}

# ------------------------------------------------------------------------------
# SECURITY & BASTION CONFIGURATION
# ------------------------------------------------------------------------------
variable "gateway_allowed_ip" {
  description = "The Elastic IP (CIDR) of the QA Gateway/Bastion. Only this IP will be allowed Ingress access (SSH/HTTP). Format: x.x.x.x/32"
  type        = string
}