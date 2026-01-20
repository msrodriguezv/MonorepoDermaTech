# ==============================================================================
# VARIABLES: NODE A CONFIGURATION (PROD)
# ==============================================================================

# --- Networking Ranges ---
variable "node_a_cidr" {
  description = "CIDR block for Node A VPC"
  type        = string
  default     = "10.3.0.0/16"
}

# --- Whitelisting CIDRs (Used for Security Group ingress rules) ---
variable "prod_cidr" {
  description = "CIDR block for PROD Hub VPC (ALB Traffic)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "events_cidr" {
  description = "CIDR block for Events VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "state_cidr" {
  description = "CIDR block for State VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "node_b_cidr" {
  description = "CIDR block for Node B VPC"
  type        = string
  default     = "10.4.0.0/16"
}

# --- Administrative Access ---
variable "prod_bastion_ip" {
  description = "Private IP of PROD Bastion for direct management"
  type        = string
  default     = "10.0.1.59/32"
}