# ==============================================================================
# OUTPUTS: NODE A INFRASTRUCTURE
# Used by QA Hub for routing injection and Peering orchestration
# ==============================================================================

output "NODE_A_PUBLIC_IP" { 
  description = "Elastic IP attached to Node A (For SSH/Maintenance)"
  value       = module.compute.public_ip 
}

output "NODE_A_PRIVATE_IP" { 
  description = "Fixed Internal IP used by the Master Load Balancer"
  value       = "10.3.1.10" 
}

output "vpc_id" {
  description = "The ID of the Node A VPC"
  value       = module.networking.vpc_id
}

output "route_table_id" {
  description = "Public Route Table ID used for peering route injection"
  value       = module.networking.public_route_table_id
}