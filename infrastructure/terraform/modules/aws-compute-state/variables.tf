# ==============================================================================
# MODULE VARIABLES: AWS COMPUTE STATE
# ==============================================================================

variable "region" { type = string }
variable "availability_zone" { type = string }
variable "project_name" { type = string }
variable "environment" { type = string }

variable "vpc_id" { type = string }
variable "public_subnet_id" { type = string }
variable "ami_id" { type = string }

variable "private_ip_address" { type = string }
variable "gateway_allowed_ip" { type = string }

variable "app_nodes_ips" {
  type        = list(string)
  description = "List of App Nodes CIDRs allowed to access Redis"
}

variable "eip_allocation_id" {
  description = "The AWS Allocation ID (eipalloc-...) of the pre-existing IP for State"
  type        = string
}