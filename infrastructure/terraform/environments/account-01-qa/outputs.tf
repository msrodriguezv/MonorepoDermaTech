# ==============================================================================
# OUTPUTS: QA HUB INFRASTRUCTURE
# ==============================================================================

output "QA_GATEWAY_PUBLIC_IP" {
  description = "Public IP of the Bastion Host / Gateway"
  value       = module.gateway.final_public_ip
}

output "QA_GATEWAY_PRIVATE_IP" {
  description = "Internal IP of the Bastion Host"
  value       = module.gateway.bastion_private_ip
}

output "QA_VPC_ID" {
  description = "VPC ID of the QA Hub"
  value       = module.networking.vpc_id
}