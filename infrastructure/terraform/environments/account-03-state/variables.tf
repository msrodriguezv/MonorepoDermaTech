# ==============================================================================
# VARIABLES: STATE SERVICE CONFIGURATION
# ==============================================================================

# --- Networking Ranges ---
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

variable "node_a_cidr" {
  description = "CIDR block for Node A VPC"
  type        = string
  default     = "10.3.0.0/16"
}

variable "node_b_cidr" {
  description = "CIDR block for Node B VPC"
  type        = string
  default     = "10.4.0.0/16"
}

# --- Administrative Access ---
variable "qa_bastion_ip" {
  description = "Private IP of the QA Bastion for SSH/UI access"
  type        = string
  default     = "10.0.1.59/32"
}

# --- AWS Account IDs ---
variable "qa_account_id" {
  default = "474829115013"
}

variable "events_account_id" {
  default = "528062813765"
}

variable "state_account_id" {
  default = "957842195675"
}

variable "node_a_account_id" {
  default = "475100560521"
}

variable "node_b_account_id" {
  default = "125941635234"
}

# --- Workflow Control Flag (CRITICAL) ---
variable "enable_peering_acceptance" {
  description = "Set to true only in the final workflow step to accept peering requests"
  type        = bool
  default     = false
}