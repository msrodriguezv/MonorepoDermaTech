# ==============================================================================
# OUTPUTS: PROD HUB INFRASTRUCTURE
# ==============================================================================

output "PROD_GATEWAY_PUBLIC_IP" {
  description = "Public IP of the Bastion Host / Gateway (Fixed EIP)"
  value       = module.gateway.final_public_ip
}

output "PROD_GATEWAY_PRIVATE_IP" {
  description = "Internal IP of the Bastion Host for SSH Tunneling"
  value       = module.gateway.bastion_private_ip
}

output "PROD_VPC_ID" {
  description = "VPC ID of the PROD Hub Environment"
  value       = module.networking.vpc_id
}

# --- GLOBAL ENTRY POINT: ALB DNS ---
output "PROD_ALB_DNS_NAME" {
  description = "The DNS name of the Production Load Balancer. Use this to access the application."
  value       = aws_lb.main_alb.dns_name
}