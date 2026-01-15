# ==============================================================================
# MODULE VARIABLES
# Context: AWS Compute State (Redis, Prometheus, Grafana)
# Purpose: Input definitions for the caching and monitoring infrastructure
# ==============================================================================

# ------------------------------------------------------------------------------
# NETWORK & PROJECT CONTEXT
# ------------------------------------------------------------------------------
variable "region" {
  description = "AWS Region for availability zone selection"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project identifier for tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., infra-state)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the instance will be deployed"
  type        = string
}

variable "public_subnet_id" {
  description = "Subnet ID for the instance placement"
  type        = string
}

# ------------------------------------------------------------------------------
# COMPUTE CONFIGURATION
# ------------------------------------------------------------------------------
variable "ami_id" {
  description = "AMI ID for the EC2 Instance (Amazon Linux 2023)"
  type        = string
}

# ------------------------------------------------------------------------------
# SECURITY & FIREWALL (WHITELISTING)
# ------------------------------------------------------------------------------
variable "gateway_allowed_ip" {
  description = "CIDR of the QA Gateway/Bastion allowed for SSH/Web UI access. (e.g., 100.x.x.x/32)"
  type        = string
}

variable "app_nodes_ips" {
  description = "List of CIDRs for Node A and Node B. Allowed to access Redis (6379)."
  type        = list(string)
}