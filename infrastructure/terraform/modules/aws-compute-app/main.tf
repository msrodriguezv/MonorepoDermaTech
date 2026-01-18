# ==============================================================================
# MODULE: AWS COMPUTE APP (WORKER NODES)
# Context: Node A (1a) & Node B (1b)
# Purpose: Hosts NestJS Microservices and Flutter Frontend via Docker
# Specs: t3.large (8GB RAM) | 25GB Root
# ==============================================================================

# ==============================================================================
# 1. SECURITY GROUP
# ==============================================================================
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-${var.environment}-sg"
  description = "Security Group for Application Worker Nodes (Bastion Protected)"
  vpc_id      = var.vpc_id

  # --- INGRESS: SSH ACCESS (BASTION ONLY) ---
  ingress {
    description = "SSH Access from QA Bastion Only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.gateway_allowed_ip] 
  }

  # --- INGRESS: APPLICATION PORTS (INTERNAL ROUTING) ---
  ingress {
    description = "Microservices Traffic from QA Gateway"
    from_port   = 3000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = [var.gateway_allowed_ip] 
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
# 2. DATA SOURCE: ELASTIC IP (BLINDADO)
# Reads the existing IP from AWS by Allocation ID.
# ==============================================================================
data "aws_eip" "app_eip" {
  id = var.eip_allocation_id
}

# ==============================================================================
# 3. EC2 INSTANCE (WORKER NODE)
# ==============================================================================
resource "aws_instance" "app_worker" {
  ami             = var.ami_id
  instance_type   = "t3.large" 
  subnet_id       = var.public_subnet_id
  key_name          = "vockey"
  
  # CRITICAL: Fixed Private IP
  private_ip      = var.private_ip_address 
  
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

    # C. INSTALL DOCKER COMPOSE V2
    mkdir -p /usr/local/lib/docker/cli-plugins
    curl -SL https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

    # D. SWAP MEMORY CONFIGURATION
    dd if=/dev/zero of=/swapfile bs=128M count=32
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

    # E. APPLICATION CONFIGURATION
    mkdir -p /home/ec2-user/app
    chown -R ec2-user:ec2-user /home/ec2-user/app

    # F. ENVIRONMENT VARIABLES INJECTION
    cat <<ENV > /home/ec2-user/app/.env_infrastructure
    # --- Infrastructure Static IPs ---
    EVENTS_HOST=10.1.1.50
    STATE_HOST=10.2.1.100
    REDIS_HOST=10.2.1.100
    KAFKA_BROKER=10.1.1.50:9092
    ENV

    echo "[INFO] Cloud-Init Complete."
  EOF
}

# ==============================================================================
# 4. EIP ASSOCIATION
# ==============================================================================
resource "aws_eip_association" "app_eip_assoc" {
  instance_id   = aws_instance.app_worker.id
  allocation_id = data.aws_eip.app_eip.id
}

output "public_ip" { 
  value = data.aws_eip.app_eip.public_ip 
}