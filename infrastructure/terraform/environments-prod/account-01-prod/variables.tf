# ==============================================================================
# VARIABLES: PROD HUB CONFIGURATION
# ==============================================================================

# --- Networking Ranges ---
variable "prod_cidr" {
  description = "CIDR block for PROD VPC"
  default     = "10.0.0.0/16"
}

# NEW: Range for the secondary subnet required by ALB
variable "prod_public_subnet_b_cidr" {
  description = "CIDR block for the secondary PROD subnet (AZ 1b)"
  default     = "10.0.2.0/24"
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

# --- AWS Account IDs (For Peering Authentication - PROD) ---
variable "prod_account_id"   { default = "905418440925" }
variable "events_account_id" { default = "138424274847" }
variable "state_account_id"  { default = "322919475477" }
variable "node_a_account_id" { default = "098535864734" }
variable "node_b_account_id" { default = "421062736652" }