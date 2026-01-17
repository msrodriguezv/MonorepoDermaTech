# ==============================================================================
# VARIABLES: NODE B CONFIGURATION
# ==============================================================================

# --- Networking Ranges (CIDR Blocks) ---
variable "qa_cidr"           { default = "10.0.0.0/16" }
variable "events_cidr"       { default = "10.1.0.0/16" }
variable "state_cidr"        { default = "10.2.0.0/16" }
variable "node_a_cidr"       { default = "10.3.0.0/16" }
variable "node_b_cidr"       { default = "10.4.0.0/16" }

# --- Administrative Access (Whitelisting) ---
# Restricted to the private IP of the QA Bastion for security.
variable "qa_bastion_ip"      { default = "10.0.1.59/32" }
variable "events_rabbitmq_ip"  { default = "10.1.1.50/32" }
variable "state_redis_ip"      { default = "10.2.1.100/32" }

# --- AWS Account Identifiers (Permanent) ---
variable "events_account_id" { default = "528062813765" }
variable "state_account_id"  { default = "957842195675" }
variable "qa_account_id"     { default = "474829115013" }

# --- Discovery Placeholders ---
# IDs are fetched dynamically in main.tf via Data Sources. 
# Defaults are empty to prevent stale ID conflicts during rebuilds.
variable "events_vpc_id"     { type = string; default = "" }
variable "state_vpc_id"      { type = string; default = "" }