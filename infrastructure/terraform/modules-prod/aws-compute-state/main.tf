# ==============================================================================
# MODULE: AWS COMPUTE STATE
# Context: Redis, Prometheus, Grafana (PROD / QA)
# Purpose: Database & Monitoring Server with INDESTRUCTIBLE IP and Storage
# Instance: t3.large (8GB RAM) for Monitoring Stack
# ==============================================================================

# ==============================================================================
# 1. SSH KEY PAIR (INJECTED FOR GITHUB ACTIONS)
# ==============================================================================
resource "aws_key_pair" "deployer" {
  key_name   = "clave-maestra-final-v2"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDHfNX1CHq9xvO5DiUcm0Id1wpjLK/htvEaATxEeBIt4cbLJ5kn+IAUhhB/gvK/BEkHXZnLeZ1/+d/NEAQmFjTDtMEK1bEO1qlPLxMrgIxBbDzAVlvZ+ADBSFRQ94LXq73swJvej9z9jLnjKDSiGu5m3FoJbJnuYTmWN/DociUWZ2ADg/xnnBDJUgn13/mBf9L5tH8HWRrve8wqxgaqLn4F/97O2ClcGI5r3SSR5m+GaVeV4al8UiALK0ZXWvzjA3/gStY61tZuj1HD6xWAJ3wIvPgdWOrU7bzVt7DmzBJhNSnRO3fOwGbVpvM8cCslv41Nos9VPuC5A887PdcxGOIKjn6GN1WlXxctk9ORrJekJUFHr5KDPNLjl/i5wijgdoRfufhSuQflluYiZCnnvYJMGBsg9XHNSORb9FeOugEARtlrVUhAfkiHcbFNVUvpE8twpvevCNydA2eWF6GngV79PL2NEmnVXes2iAUgTKYbCgNAmcCs2rxVT8oZGDQBrHTDnRj9mfvTEWR5GDJho46bd/nT/AfyJWLHdhhttrA8Pqwk66CKgi7PSVXdCqSv3lJ/5JmOMyuSb/8c9r5yWwBBnmKTZsCS5OE9ca5f5tNe296g00W5SOiUvpRAPvAHIgjjYIVJgd3qQSGTMSLj8vlsVZ/jyBXrO/pR6/aMhCAk/w== github-actions"
}

# ==============================================================================
# 2. SECURITY GROUP
# ==============================================================================
resource "aws_security_group" "state_sg" {
  name        = "${var.project_name}-${var.environment}-sg"
  description = "Security Group for State & Monitoring"
  vpc_id      = var.vpc_id

  # Admin Access (SSH) - TEMPORARY OPEN FOR GITHUB ACTIONS
  ingress {
    description = "Allow SSH from GitHub Actions (Temporary)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # Monitoring UI Access (Grafana 3000, Prometheus 9090) from Gateway only
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.gateway_allowed_ip] 
  }
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.gateway_allowed_ip] 
  }

  # Redis Access (6379) from App Nodes (Internal Only)
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = var.app_nodes_ips
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${var.environment}-sg" }
}

# ==============================================================================
# 3. DATA SOURCE: ELASTIC IP (BLINDADO POR ID)
# Terraform reads the existing IP. It will NEVER destroy it.
# ==============================================================================
data "aws_eip" "state_eip" {
  id = var.eip_allocation_id
}

# ==============================================================================
# 4. PERSISTENT STORAGE (10GB)
# ==============================================================================
resource "aws_ebs_volume" "state_data_volume" {
  availability_zone = var.availability_zone
  size              = 10
  type              = "gp3"
  encrypted         = true

  tags = {
    Name      = "${var.project_name}-${var.environment}-persistence"
    ManagedBy = "terraform"
  }

  lifecycle {
    prevent_destroy = false # temporal(false) CRITICAL: DATA PROTECTION
  }
}

# ==============================================================================
# 5. EC2 INSTANCE (STATE SERVER)
# ==============================================================================
resource "aws_instance" "state_worker" {
  ami               = var.ami_id
  instance_type     = "t3.large" 
  subnet_id         = var.public_subnet_id
   
  # CRITICAL: Use the injected Key Pair
  key_name          = aws_key_pair.deployer.key_name
   
  # CRITICAL: Fixed Private IP
  private_ip        = var.private_ip_address
   
  availability_zone = var.availability_zone
   
  vpc_security_group_ids      = [aws_security_group.state_sg.id]
  user_data_replace_on_change = true

  # ROOT VOLUME (25GB for Docker/System)
  root_block_device {
    volume_size           = 25
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = { Name = "${var.project_name}-${var.environment}-server" }

  # MINIMAL USER DATA: Only OS prep, Docker install, and Disk mount.
  # Service orchestration is handled by GitHub Actions.
  user_data = <<-EOF
    #!/bin/bash
    set -e
     
    # --- INSTALLATION ---
    dnf update -y
    dnf install -y docker git htop
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user

    # --- SWAP SETUP (Crucial for Prometheus/Java stability) ---
    dd if=/dev/zero of=/swapfile bs=128M count=32
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

    # --- PERSISTENT DISK MOUNTING ---
    # Detect if it's nvme1n1 (Nitro) or xvdf (Legacy)
    if [ -e /dev/nvme1n1 ]; then
      DATA_DISK="/dev/nvme1n1"
    else
      DATA_DISK="/dev/xvdf"
    fi
    MOUNT_POINT="/data"
     
    # Wait for disk
    while [ ! -b $DATA_DISK ]; do echo "Waiting for disk $DATA_DISK..."; sleep 5; done
     
    # Only format if new (Protects Data)
    if ! blkid $DATA_DISK; then 
      mkfs -t xfs $DATA_DISK
    fi
     
    mkdir -p $MOUNT_POINT
    mount $DATA_DISK $MOUNT_POINT
     
    if ! grep -qs "$MOUNT_POINT" /etc/fstab; then
      echo "$DATA_DISK $MOUNT_POINT xfs defaults,nofail 0 2" >> /etc/fstab
    fi
     
    # --- DIRECTORIES & PERMISSIONS ---
    # Ensure directories exist so Docker doesn't create them with root:root
    mkdir -p $MOUNT_POINT/redis_data $MOUNT_POINT/prometheus_data $MOUNT_POINT/grafana_data $MOUNT_POINT/prometheus_config
     
    # Set permissive permissions to avoid Docker boot loops on persistent volumes
    # (Acceptable for this specific academic context to allow rapid GH Actions deployment)
    chmod -R 777 $MOUNT_POINT

    echo "✅ Instance Ready for GitHub Actions Deployment"
  EOF
}

# ==============================================================================
# 6. ATTACHMENTS & ASSOCIATIONS
# ==============================================================================
resource "aws_volume_attachment" "state_ebs_att" {
  device_name  = "/dev/sdf"
  volume_id    = aws_ebs_volume.state_data_volume.id
  instance_id  = aws_instance.state_worker.id
  force_detach = true
}

resource "aws_eip_association" "state_eip_assoc" {
  instance_id   = aws_instance.state_worker.id
  allocation_id = data.aws_eip.state_eip.id
}

output "public_ip" { value = data.aws_eip.state_eip.public_ip }