# ==============================================================================
# OUTPUTS: NODE B INFRASTRUCTURE
# Used by QA Hub for routing injection
# ==============================================================================

output "NODE_B_PUBLIC_IP" { 
  description = "Elastic IP attached to Node B"
  value       = module.compute.public_ip 
}

output "NODE_B_PRIVATE_IP" { 
  description = "Fixed Internal IP"
  value       = "10.4.1.10" 
}

output "vpc_id" {
  description = "The ID of the Node B VPC"
  value       = module.networking.vpc_id
}

output "route_table_id" {
  description = "Public Route Table ID. CRITICAL: Used by QA Hub to inject return routes."
  value       = module.networking.public_route_table_id
}