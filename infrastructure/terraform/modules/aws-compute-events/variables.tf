# ==============================================================================
# MODULE VARIABLES
# Context: AWS Compute Events (Kafka, RabbitMQ, Zookeeper)
# Purpose: Input definitions for the messaging infrastructure
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
  description = "Environment name (e.g., infra-events)"
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

variable "private_ip_address" {
  description = "Internal IP (Critical for service discovery, e.g., 10.0.1.50)"
  type        = string
}

# ------------------------------------------------------------------------------
# SECURITY & FIREWALL (WHITELISTING)
# ------------------------------------------------------------------------------
variable "gateway_allowed_ip" {
  description = "CIDR of the QA Gateway/Bastion allowed for SSH (e.g., 100.x.x.x/32)"
  type        = string
}

variable "app_nodes_ips" {
  description = "List of CIDRs for Node A and Node B. Only these IPs can access Data Ports (Kafka/RabbitMQ)."
  type        = list(string)
}