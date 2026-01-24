# ==============================================================================
# OUTPUTS: EVENTS INFRASTRUCTURE
# Used by the CI/CD Pipeline and Cross-Account references
# ==============================================================================

output "vpc_id" {
  description = "The ID of the Events VPC"
  value       = module.networking.vpc_id
}

output "route_table_id" {
  description = "Public Route Table ID. CRITICAL: Used by QA Hub to inject return routes."
  # Nota: Usamos la tabla pública porque tu instancia tiene EIP y está en la subnet pública.
  value       = module.networking.public_route_table_id
}

output "events_public_ip" { 
  description = "Elastic IP attached to the Messaging Server"
  value       = module.compute.public_ip 
}

output "events_private_ip" {
  description = "Fixed Internal IP for Inter-VPC communication"
  value       = "10.1.1.50"
}