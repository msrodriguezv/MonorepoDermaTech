# ==============================================================================
# VARIABLES: QA HUB CONFIGURATION
# ==============================================================================

# --- Networking Ranges ---
variable "qa_cidr" {
  description = "CIDR block for QA VPC"
  default     = "10.0.0.0/16"
}

variable "events_cidr" {
  description = "CIDR block for Events VPC (for routing)"
  default     = "10.1.0.0/16"
}

variable "state_cidr" {
  description = "CIDR block for State VPC (for routing)"
  default     = "10.2.0.0/16"
}

variable "node_a_cidr" {
  description = "CIDR block for Node A VPC (for routing)"
  default     = "10.3.0.0/16"
}

variable "node_b_cidr" {
  description = "CIDR block for Node B VPC (for routing)"
  default     = "10.4.0.0/16"
}

# --- VPC IDs Injection (REQUIRED FOR CI/CD WORKFLOWS) ---
# These values are injected by the pipeline from previous deployment steps
variable "events_vpc_id" {
  description = "VPC ID of the Events Account"
  type        = string
  default     = ""
}

variable "state_vpc_id" {
  description = "VPC ID of the State Account"
  type        = string
  default     = ""
}

variable "node_a_vpc_id" {
  description = "VPC ID of the Node A Account"
  type        = string
  default     = ""
}

variable "node_b_vpc_id" {
  description = "VPC ID of the Node B Account"
  type        = string
  default     = ""
}

# --- AWS Account IDs (For Peering Authentication) ---
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