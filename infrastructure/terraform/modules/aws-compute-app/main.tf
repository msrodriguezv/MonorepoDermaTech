# ==============================================================================
# MODULE: AWS COMPUTE APP (WORKER NODES)
# Context: Node A & Node B
# Purpose: Hosts NestJS Microservices and Flutter Frontend via Docker
# ==============================================================================

# ==============================================================================
# 1. SECURITY GROUP
# Description: Defines strict firewall rules implementing the Bastion Host pattern.
# ==============================================================================
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-${var.environment}-sg"
  description = "Security Group for Application Worker Nodes (Bastion Protected)"
  vpc_id      = var.vpc_id

  # --- INGRESS: SSH ACCESS (BASTION ONLY) ---
  # CRITICAL SECURITY: Direct SSH from 0.0.0.0/0 is REMOVED.
  # Access is restricted exclusively to the QA Gateway/Bastion IP.
  ingress {
    description = "SSH Access from QA Bastion Only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.gateway_allowed_ip] # QA Gateway Elastic IP
  }

  # --- INGRESS: APPLICATION PORTS (INTERNAL ROUTING) ---
  # Range 3000-4000: Standard ports for NestJS Microservices.
  # Traffic is only accepted if proxied via Nginx on the QA Gateway.
  ingress {
    description = "Microservices Traffic from QA Gateway"
    from_port   = 3000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = [var.gateway_allowed_ip] # QA Gateway Elastic IP
  }

  # --- EGRESS: OUTBOUND TRAFFIC ---
  # Required for:
  # 1. Pulling Docker images from Docker Hub.
  # 2. Connecting to MongoDB Atlas / PostgreSQL (PaaS).
  # 3. Pushing backups to external On-Premise servers.
  egress {
    description = "Allow Unrestricted Outbound Traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-sg"
  }
}

# ==============================================================================
# 2. EC2 INSTANCE (WORKER NODE)
# Description: The compute unit running the Dockerized microservices stack.
# ==============================================================================
resource "aws_instance" "app_worker" {
  ami           = var.ami_id
  instance_type = "t3.large" 
  subnet_id     = var.public_subnet_id
  private_ip    = var.private_ip_address 
  
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # --------------------------------------------------------------------------
  # AUTOMATION FIX: FORCE REPLACEMENT ON USER_DATA CHANGE
  # --------------------------------------------------------------------------
  # This ensures that if you edit the cloud-init script (user_data), 
  # Terraform will AUTOMATICALLY destroy and recreate the instance 
  # to apply the new configuration. No manual intervention required.
  user_data_replace_on_change = true  # <--- ¡ESTA ES LA CLAVE DE LA AUTOMATIZACIÓN!

  root_block_device {
    volume_size           = 25
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-server"
  }

  # --------------------------------------------------------------------------
  # USER DATA: AUTOMATED PROVISIONING SCRIPT
  # --------------------------------------------------------------------------
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
    # FIXED: IPs updated to match the Peering CIDRs (Events: 10.1, State: 10.2)
    cat <<ENV > /home/ec2-user/app/.env_infrastructure
    # --- Infrastructure Static IPs ---
    # WARNING: These MUST match the private_ip configured in Account 03 & 04
    EVENTS_HOST=10.1.1.50
    STATE_HOST=10.2.1.100
    REDIS_HOST=10.2.1.100
    KAFKA_BROKER=10.1.1.50:9092
    ENV

    echo "[INFO] Cloud-Init Complete."
  EOF
}

# ==============================================================================
# 3. ELASTIC IP (EIP)
# Description: Static Public IP assignment.
# NOTE: Required for internet egress (Docker pull) in absence of NAT Gateway.
# ==============================================================================
resource "aws_eip" "app_eip" {
  domain = "vpc"
  tags = { Name = "${var.project_name}-${var.environment}-eip" }
  
  # PROTECTION POLICY:
  # Prevents Terraform from destroying this IP address during updates.
  # This guarantees the IP remains allocated to the account even if the instance is replaced.
  lifecycle { 
    prevent_destroy = true 
  }
}

# ==============================================================================
# 4. EIP ASSOCIATION
# Description: Binds the protected IP to the specific EC2 instance.
# ==============================================================================
resource "aws_eip_association" "app_eip_assoc" {
  instance_id   = aws_instance.app_worker.id
  allocation_id = aws_eip.app_eip.id
}

output "public_ip" { 
  description = "The public IP address of the Worker Node (Protected)"
  value        = aws_eip.app_eip.public_ip 
}