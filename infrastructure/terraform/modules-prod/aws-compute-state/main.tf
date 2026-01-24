# ==============================================================================
# MODULE: AWS COMPUTE STATE
# Context: Redis, Prometheus, Grafana
# Purpose: Database & Monitoring Server with INDESTRUCTIBLE IP and Storage
# Instance: t3.large (8GB RAM) for Monitoring Stack (PROD)
# ==============================================================================

# ==============================================================================
# 1. SSH KEY PAIR
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

# ----------------------------------------------------------------------------
# ROBUST RULE: SSH FROM ENTIRE PROD NETWORK (HUB)
# ----------------------------------------------------------------------------
  ingress {
    description = "Allow SSH from PROD Network (Bastion)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] 
  }

  # Monitoring UI Access (Grafana 3000, Prometheus 9090)
  # Permitimos toda la red PROD para evitar timeouts en el túnel
  ingress {
    description = "Allow Grafana UI from PROD Network"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] 
  }
  ingress {
    description = "Allow Prometheus UI from PROD Network"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] 
  }

  # Redis Access (6379) from App Nodes (Internal Only)
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = var.app_nodes_ips
  }

  # Outbound Traffic (Allow All)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${var.environment}-sg" }
}

# ==============================================================================
# 3. DATA SOURCE: ELASTIC IP
# ==============================================================================
data "aws_eip" "state_eip" {
  id = var.eip_allocation_id
}

# ==============================================================================
# 4. PERSISTENT STORAGE (10GB) - PROTEGIDO
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
    prevent_destroy = true # CRITICAL: DATA PROTECTION (PROD)
  }
}

# ==============================================================================
# 5. EC2 INSTANCE (STATE SERVER)
# ==============================================================================
resource "aws_instance" "state_worker" {
  ami               = var.ami_id
  instance_type     = "t3.large" 
  subnet_id         = var.public_subnet_id
  
  key_name          = aws_key_pair.deployer.key_name
  private_ip        = var.private_ip_address
  availability_zone = var.availability_zone
  
  vpc_security_group_ids      = [aws_security_group.state_sg.id]
  user_data_replace_on_change = true

  root_block_device {
    volume_size            = 25
    volume_type            = "gp3"
    delete_on_termination = true
  }

  tags = { Name = "${var.project_name}-${var.environment}-server" }

  user_data = <<-EOF
    #!/bin/bash
    set -e
    
    # --- INSTALLATION ---
    dnf update -y
    dnf install -y docker git htop
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user

    # --- SWAP SETUP ---
    dd if=/dev/zero of=/swapfile bs=128M count=32
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

    # --- PERSISTENT DISK MOUNTING ---
    if [ -e /dev/nvme1n1 ]; then
      DATA_DISK="/dev/nvme1n1"
    else
      DATA_DISK="/dev/xvdf"
    fi
    MOUNT_POINT="/data"
    
    while [ ! -b $DATA_DISK ]; do echo "Waiting for disk $DATA_DISK..."; sleep 5; done
    
    if ! blkid $DATA_DISK; then 
      mkfs -t xfs $DATA_DISK
    fi
    
    mkdir -p $MOUNT_POINT
    mount $DATA_DISK $MOUNT_POINT
    
    if ! grep -qs "$MOUNT_POINT" /etc/fstab; then
      echo "$DATA_DISK $MOUNT_POINT xfs defaults,nofail 0 2" >> /etc/fstab
    fi
    
    # --- DIRECTORIES ---
    mkdir -p $MOUNT_POINT/redis_data $MOUNT_POINT/prometheus_data $MOUNT_POINT/grafana_data $MOUNT_POINT/prometheus_config
    
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