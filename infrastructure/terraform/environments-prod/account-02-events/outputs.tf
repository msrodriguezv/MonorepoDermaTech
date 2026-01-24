# ==============================================================================
# OUTPUTS: EVENTS INFRASTRUCTURE (PROD)
# Used by the CI/CD Pipeline and Cross-Account references
# ==============================================================================

output "vpc_id" {
  description = "The ID of the Events VPC"
  value       = module.networking.vpc_id
}

output "route_table_id" {
  description = "Public Route Table ID. CRITICAL: Used by PROD Hub to inject return routes."
  value       = module.networking.public_route_table_id
}

output "events_public_ip" { 
  description = "Elastic IP attached to the Messaging Server (PROD)"
  value       = module.compute.public_ip 
}

output "events_private_ip" {
  description = "Fixed Internal IP for Inter-VPC communication"
  value       = "10.1.1.50"
}