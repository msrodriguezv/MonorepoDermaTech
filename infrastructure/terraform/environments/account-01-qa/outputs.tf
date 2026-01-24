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

# --- NEW: GLOBAL ENTRY POINT ---
output "QA_ALB_DNS_NAME" {
  description = "The DNS name of the Load Balancer. Use this to access the application."
  value       = aws_lb.main_alb.dns_name
}