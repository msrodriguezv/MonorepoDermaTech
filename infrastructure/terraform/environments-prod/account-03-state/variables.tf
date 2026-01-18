# ==============================================================================
# VARIABLES: STATE SERVICE CONFIGURATION
# ==============================================================================

# --- Networking Ranges ---
variable "qa_cidr"           { default = "10.0.0.0/16" }
variable "events_cidr"       { default = "10.1.0.0/16" }
variable "state_cidr"        { default = "10.2.0.0/16" }
variable "node_a_cidr"       { default = "10.3.0.0/16" }
variable "node_b_cidr"       { default = "10.4.0.0/16" }

# --- Administrative Access ---
variable "qa_bastion_ip"      { default = "10.0.1.59/32" }

# --- AWS Account IDs ---
variable "qa_account_id"     { default = "474829115013" }
variable "events_account_id" { default = "528062813765" }
variable "state_account_id"  { default = "957842195675" }
variable "node_a_account_id" { default = "475100560521" }
variable "node_b_account_id" { default = "125941635234" }