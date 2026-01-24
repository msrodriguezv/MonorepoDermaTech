# ==============================================================================
# OUTPUTS: STATE INFRASTRUCTURE (PROD)
# Used by PROD Hub for routing injection
# ==============================================================================

output "vpc_id" {
  description = "The ID of the State VPC"
  value       = module.networking.vpc_id
}

output "route_table_id" {
  description = "Public Route Table ID. CRITICAL: Used by PROD Hub to inject return routes."
  value       = module.networking.public_route_table_id
}

output "state_public_ip" { 
  description = "Elastic IP attached to the State Server (PROD)"
  value       = module.compute.public_ip 
}

output "state_private_ip" {
  description = "Fixed Internal IP"
  value       = "10.2.1.60"
}