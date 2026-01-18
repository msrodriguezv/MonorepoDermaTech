# ==============================================================================
# OUTPUTS: NODE A INFRASTRUCTURE
# Used by QA Hub for routing injection
# ==============================================================================

output "NODE_A_PUBLIC_IP" { 
  description = "Elastic IP attached to Node A"
  value       = module.compute.public_ip 
}

output "NODE_A_PRIVATE_IP" { 
  description = "Fixed Internal IP"
  value       = "10.3.1.10" 
}

output "vpc_id" {
  description = "The ID of the Node A VPC"
  value       = module.networking.vpc_id
}

output "route_table_id" {
  description = "Public Route Table ID. CRITICAL: Used by QA Hub to inject return routes."
  value       = module.networking.public_route_table_id
}