# infrastructure/terraform/modules/aws-gateway-node/main.tf

# 1. Security Group
# Acts as the Firewall for the Bastion/Gateway
resource "aws_security_group" "gateway_sg" {
  name        = "${var.project_name}-${var.environment}-gateway-sg"
  description = "Security group for API Gateway Nginx"
  vpc_id      = var.vpc_id

  # Inbound HTTP (Public)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound HTTPS (Public)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound SSH (Admin Access)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound (Allow all)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. EC2 Instance (Bastion & Load Balancer)
resource "aws_instance" "gateway" {
  ami                    = var.ami_id
  instance_type          = "t3.medium" # Robust enough for Nginx & traffic
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.gateway_sg.id]

  # Install Nginx, Docker, Git
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx git docker
              systemctl start nginx
              systemctl enable nginx
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-gateway"
  }
}

# 3. ELASTIC IP MANAGEMENT (CRITICAL)
# We define the resource here, but we will IMPORT the existing ID via CLI.
# 'prevent_destroy' ensures Terraform fails if it tries to delete this IP.
resource "aws_eip" "gateway_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-eip"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# 4. Association
# Binds the Static IP to the Instance
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.gateway.id
  allocation_id = aws_eip.gateway_eip.id
}

output "final_public_ip" {
  value = aws_eip.gateway_eip.public_ip
}