# ==============================================================================
# VARIABLES: NODE A CONFIGURATION
# ==============================================================================

# --- Networking Ranges ---
variable "qa_cidr" {
  description = "CIDR block for QA VPC"
  default     = "10.0.0.0/16"
}

variable "events_cidr" {
  description = "CIDR block for Events VPC"
  default     = "10.1.0.0/16"
}

variable "state_cidr" {
  description = "CIDR block for State VPC"
  default     = "10.2.0.0/16"
}

variable "node_a_cidr" {
  description = "CIDR block for Node A VPC"
  default     = "10.3.0.0/16"
}

variable "node_b_cidr" {
  description = "CIDR block for Node B VPC"
  default     = "10.4.0.0/16"
}

# --- Administrative Access ---
variable "qa_bastion_ip" {
  description = "Private IP of QA Bastion"
  default     = "10.0.1.59/32"
}

# --- AWS Account Identifiers ---
variable "events_account_id" {
  default = "528062813765"
}

variable "state_account_id" {
  default = "957842195675"
}

# --- Workflow Injected IDs (NO DATA LOOKUPS) ---
variable "events_vpc_id" {
  description = "VPC ID of Events Account (Injected by Workflow)"
  type        = string
}

variable "state_vpc_id" {
  description = "VPC ID of State Account (Injected by Workflow)"
  type        = string
}