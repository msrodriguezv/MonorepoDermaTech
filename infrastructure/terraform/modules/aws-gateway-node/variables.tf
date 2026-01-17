# ==============================================================================
# MODULE VARIABLES: AWS GATEWAY NODE
# ==============================================================================

variable "project_name" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "ami_id" { type = string }
variable "public_subnet_id" { type = string }

variable "availability_zone" {
  type        = string
  description = "AZ for the instance and persistent volume"
}

variable "bastion_private_ip" {
  type        = string
  description = "Fixed private IP for the bastion instance"
}

variable "eip_allocation_id" {
  type        = string
  description = "Allocation ID of the existing Elastic IP"
}