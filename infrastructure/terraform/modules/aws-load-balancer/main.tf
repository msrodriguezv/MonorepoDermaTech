# infrastructure/terraform/modules/aws-load-balancer/main.tf

# 1. Security Group (The Firewall)
# IMPORTANT: Defines which ports Cloudflare can access
resource "aws_security_group" "gateway_sg" {
  name        = "${var.project_name}-${var.environment}-gateway-sg"
  description = "Security group for Gateway instance"
  vpc_id      = var.vpc_id

  # Inbound HTTP (Port 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # The professor will restrict this via Cloudflare later
  }

  # Inbound HTTPS (Port 443)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound: Allow all traffic so the instance can update itself
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-gateway-sg"
  }
}

# 2. EC2 Instance (The Gateway Server)
# We use t3.micro (cost-effective for Academy accounts)
resource "aws_instance" "gateway" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.gateway_sg.id]

  # User Data script to install Nginx on boot (Basic Health Check)
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install nginx -y
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>Dermatech Gateway (${var.environment}) is Running!</h1>" > /usr/share/nginx/html/index.html
              EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-gateway"
  }
}

# 3. THE CROWN JEWEL: Elastic IP (Static Public IP)
# This IP will NOT change unless this specific resource is destroyed.
resource "aws_eip" "gateway_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-eip"
  }
}

# 4. Associate the Static IP to the Gateway Instance
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.gateway.id
  allocation_id = aws_eip.gateway_eip.id
}

# --- OUTPUTS ---
output "final_public_ip" {
  value       = aws_eip.gateway_eip.public_ip
  description = "THE STATIC IP FOR CLOUDFLARE CONFIGURATION"
}

output "final_public_dns" {
  value       = aws_instance.gateway.public_dns
  description = "The Public DNS name assigned to the instance (standard AWS DNS)"
}