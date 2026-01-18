# ==============================================================================
# VARIABLES: NODE A CONFIGURATION
# ==============================================================================

# --- Networking Ranges ---
variable "node_a_cidr" {
  description = "CIDR block for Node A VPC"
  type        = string
  default     = "10.3.0.0/16"
}

# --- Whitelisting CIDRs (Optional usage in SG logic) ---
variable "qa_cidr" {
  description = "CIDR block for QA VPC"
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
variable "qa_bastion_ip" {
  description = "Private IP of QA Bastion"
  type        = string
  default     = "10.0.1.59/32"
}