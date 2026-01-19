# ==============================================================================
# MODULE: AWS COMPUTE APP (WORKER NODES)
# Context: Node A (1a) & Node B (1b)
# Purpose: Hosts NestJS Microservices and Flutter Frontend via Docker
# Specs: t3.large (8GB RAM) | 25GB Root
# ==============================================================================

# ==============================================================================
# 1. SSH KEY PAIR (INJECTED FOR GITHUB ACTIONS)
# ==============================================================================
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-${var.environment}-app-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDYqPfExDwWSxI3gOI/9Cdd2GeuOVLRaXw6vz5x1S0mgWc7p7BStBXWnsUIY7o8CeUoR9ZT28QiC9PiWhfsXmO3m6vsZqGUJl0UlY8N9P8n64ccCXPrD/ddKrzQV66mkN3MeBnFidUen4Zn6WdOhA92ljZm+MOpxQFznR4kyPwC57v39W9Lkc7s9i6sP+7Zj2eVf6Mlxh3IPHnGHWMFDFe/DFLEGtwEve0rJyZ+lDas6TFUzjwJ045WxBuFnrIWHJWNIBAqhsWxTdoB7JmDh6UqdAPO4iW147QoXaPN51jtQyOnECcO7/zgv07ChyJq2XwfyZggDxMNv9LAxVNadmw2pbfAtW+sRINyT4ArdVCX1I4se/2FmZJkEsKpP4QB39bDJzswPFKmOjQTNdeUO4ZGWF257FjcfvD3U//5RV+3EnixCJIVek3MVo2xejp+0V1ZgVfC2vwr6CmwyheuKloWyI08FBCa+GGEQG19E/+sOuRSxfMQx3GH2U0Ol5TBnbtsc9gIO6MrU8ZqkOOGKUyBrR3nr2w4ExXH0aJmfb8qAQkTPU2jTX+b2JSFcPtSkOb9RI3Sm2I9O8rxDpwpET1rquxZsm+Y000SaxY8PbOuFLK5lfLtnQ1sUbl+7wGHjTyJhDfQPKAmVn2wwj+b6SQdHZYN6qHsK7H9z5pG5DKW7w== ci-cd-key"
}

# ==============================================================================
# 2. SECURITY GROUP
# ==============================================================================
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-${var.environment}-sg"
  description = "Security Group for Application Worker Nodes (Bastion Protected)"
  vpc_id      = var.vpc_id

  # --- INGRESS: SSH ACCESS (TEMPORARY: OPEN FOR GITHUB ACTIONS) ---
  ingress {
    description = "Allow SSH from GitHub Actions (Temporary)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # --- INGRESS: APPLICATION PORTS (INTERNAL ROUTING) ---
  # Allows traffic from Gateway/Bastion IP to Microservices
  ingress {
    description = "Microservices Traffic from QA Gateway"
    from_port   = 3000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = [var.gateway_allowed_ip] 
  }
  
  # Allow HTTP (80) for Frontend if accessed directly or via LB
  ingress {
    description = "Frontend HTTP Access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open for testing/access. Can be restricted later.
  }

  # --- EGRESS: OUTBOUND TRAFFIC ---
  egress {
    description = "Allow Unrestricted Outbound Traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${var.environment}-sg" }
}

# ==============================================================================
# 3. DATA SOURCE: ELASTIC IP (BLINDADO)
# Reads the existing IP from AWS by Allocation ID.
# ==============================================================================
data "aws_eip" "app_eip" {
  id = var.eip_allocation_id
}

# ==============================================================================
# 4. EC2 INSTANCE (WORKER NODE)
# ==============================================================================
resource "aws_instance" "app_worker" {
  ami               = var.ami_id
  instance_type     = "t3.large" 
  subnet_id         = var.public_subnet_id
  
  # CRITICAL: Use the injected Key Pair
  key_name          = aws_key_pair.deployer.key_name
  
  # CRITICAL: Fixed Private IP
  private_ip        = var.private_ip_address 
  
  # CRITICAL: High Availability Zone (1a or 1b)
  availability_zone = var.availability_zone
  
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  user_data_replace_on_change = true

  root_block_device {
    volume_size           = 25
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = { Name = "${var.project_name}-${var.environment}-server" }

  # MINIMAL USER DATA: Only OS prep and Docker install.
  # Deployment logic moved to GitHub Actions.
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # A. SYSTEM UPDATE & DEPENDENCIES
    dnf update -y
    dnf install -y docker git htop

    # B. DOCKER ENGINE SETUP
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user

    # C. SWAP MEMORY CONFIGURATION
    dd if=/dev/zero of=/swapfile bs=128M count=32
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

    echo "✅ Instance Ready for GitHub Actions Deployment"
  EOF
}

# ==============================================================================
# 5. EIP ASSOCIATION
# ==============================================================================
resource "aws_eip_association" "app_eip_assoc" {
  instance_id   = aws_instance.app_worker.id
  allocation_id = data.aws_eip.app_eip.id
}

output "public_ip" { 
  value = data.aws_eip.app_eip.public_ip 
}