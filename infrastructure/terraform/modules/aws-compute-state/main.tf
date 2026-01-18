# ==============================================================================
# MODULE: AWS COMPUTE STATE
# Context: Redis, Prometheus, Grafana
# Purpose: Database & Monitoring Server with INDESTRUCTIBLE IP and Storage
# Instance: t3.large (8GB RAM) for Monitoring Stack
# ==============================================================================

# ==============================================================================
# 1. SECURITY GROUP
# ==============================================================================
resource "aws_security_group" "state_sg" {
  name        = "${var.project_name}-${var.environment}-sg"
  description = "Security Group for State & Monitoring"
  vpc_id      = var.vpc_id

  # Admin Access (SSH, Grafana UI 3000, Prometheus UI 9090) from QA Bastion
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.gateway_allowed_ip] 
  }
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
# 2. DATA SOURCE: ELASTIC IP (BLINDADO POR ID)
# Terraform reads the existing IP. It will NEVER destroy it.
# ==============================================================================
data "aws_eip" "state_eip" {
  id = var.eip_allocation_id
}

# ==============================================================================
# 3. PERSISTENT STORAGE (10GB)
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
    prevent_destroy = true # CRITICAL: DATA PROTECTION
  }
}

# ==============================================================================
# 4. EC2 INSTANCE (STATE SERVER)
# ==============================================================================
resource "aws_instance" "state_worker" {
  ami             = var.ami_id
  instance_type   = "t3.large" 
  subnet_id       = var.public_subnet_id
  
  # CRITICAL: Fixed Private IP (10.2.1.100)
  private_ip      = var.private_ip_address
  
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
    DATA_DISK="/dev/nvme1n1"
    MOUNT_POINT="/data"
    
    while [ ! -b $DATA_DISK ]; do echo "Waiting for disk..."; sleep 5; done
    
    # Only format if new (Protects Data)
    if ! blkid $DATA_DISK; then mkfs -t xfs $DATA_DISK; fi
    
    mkdir -p $MOUNT_POINT
    mount $DATA_DISK $MOUNT_POINT
    
    if ! grep -qs "$MOUNT_POINT" /etc/fstab; then
      echo "$DATA_DISK $MOUNT_POINT xfs defaults,nofail 0 2" >> /etc/fstab
    fi
    
    # --- DIRECTORIES & PERMISSIONS ---
    mkdir -p $MOUNT_POINT/redis_data $MOUNT_POINT/prometheus_data $MOUNT_POINT/grafana_data $MOUNT_POINT/prometheus_config
    
    # Set permissive permissions to avoid Docker boot loops on persistent volumes
    # (Acceptable for this specific academic context)
    chmod -R 777 $MOUNT_POINT

    # --- PROMETHEUS CONFIG ---
    cat <<'PROMCONF' > $MOUNT_POINT/prometheus_config/prometheus.yml
    global:
      scrape_interval: 15s
    scrape_configs:
      - job_name: 'prometheus'
        static_configs:
          - targets: ['localhost:9090']
    PROMCONF

    # --- DOCKER COMPOSE ---
    cat <<'COMPOSE' > /home/ec2-user/docker-compose.yml
    version: '3.8'
    services:
      redis:
        image: redis:alpine
        container_name: redis
        ports:
          - "6379:6379"
        # Redis persistence enabled + Password
        command: redis-server --appendonly yes --requirepass "admin123"
        volumes:
          - $MOUNT_POINT/redis_data:/data
        restart: always

      prometheus:
        image: prom/prometheus:latest
        container_name: prometheus
        ports:
          - "9090:9090"
        volumes:
          - $MOUNT_POINT/prometheus_config/prometheus.yml:/etc/prometheus/prometheus.yml
          - $MOUNT_POINT/prometheus_data:/prometheus
        command:
          - '--config.file=/etc/prometheus/prometheus.yml'
          - '--storage.tsdb.path=/prometheus'
        restart: always

      grafana:
        image: grafana/grafana:latest
        container_name: grafana
        ports:
          - "3000:3000"
        environment:
          - GF_SECURITY_ADMIN_USER=admin
          - GF_SECURITY_ADMIN_PASSWORD=admin
        volumes:
          - $MOUNT_POINT/grafana_data:/var/lib/grafana
        depends_on:
          - prometheus
        restart: always
    COMPOSE

    # --- START SERVICES ---
    cd /home/ec2-user
    docker compose up -d
  EOF
}

# ==============================================================================
# 5. ATTACHMENTS & ASSOCIATIONS
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