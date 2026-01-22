# ==============================================================================
# VARIABLES: EVENTS SERVICE CONFIGURATION (PROD)
# ==============================================================================

# --- Networking Ranges ---
variable "events_cidr" {
  description = "CIDR block for Events VPC"
  type        = string
  default     = "10.1.0.0/16"
}

# --- Whitelisting CIDRs (Security Group Rules) ---
variable "prod_cidr" {
  description = "CIDR block for PROD Hub VPC (Used in SG rules)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "state_cidr" {
  description = "CIDR block for State VPC (Used in SG rules)"
  type        = string
  default     = "10.2.0.0/16"
}

variable "node_a_cidr" {
  description = "CIDR block for Node A VPC (Used in SG rules)"
  type        = string
  default     = "10.3.0.0/16"
}

variable "node_b_cidr" {
  description = "CIDR block for Node B VPC (Used in SG rules)"
  type        = string
  default     = "10.4.0.0/16"
}

# --- Administrative Access ---
variable "prod_bastion_ip" {
  description = "Private IP of the PROD Bastion for SSH access"
  type        = string
  default     = "10.0.1.59/32"
}

# --- AWS Account Identifiers (PROD) ---
variable "events_account_id" {
  description = "Account ID for Events (Self - PROD)"
  type        = string
  default     = "138424274847"
}