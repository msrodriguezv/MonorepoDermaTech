# ==============================================================================
# MODULE: AWS COMPUTE STATE
# Context: Redis (Cache), Prometheus (Metrics), Grafana (Dashboard)
# Purpose: Provisioning of the State & Observability Server with Persistence
# ==============================================================================

# ==============================================================================
# 1. SECURITY GROUP (BASTION & INTERNAL ONLY)
# Purpose: Strict firewall rules. No public access.
# ==============================================================================
resource "aws_security_group" "state_sg" {
  name        = "${var.project_name}-${var.environment}-sg"
  description = "Security Group for State & Monitoring (Whitelisted)"
  vpc_id      = var.vpc_id

  # --- SSH ACCESS & WEB UI (Admin via Bastion) ---
  # Allows SSH (22), Grafana (3000), Prometheus (9090) ONLY from Gateway
  ingress {
    description = "Admin Access (SSH/Web) from QA Gateway"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.gateway_allowed_ip]
  }
  
  ingress {
    description = "Grafana UI from QA Gateway"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.gateway_allowed_ip]
  }

  ingress {
    description = "Prometheus UI from QA Gateway"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.gateway_allowed_ip]
  }

  # --- REDIS ACCESS (Internal App Nodes) ---
  # Only Node A and Node B can talk to Redis
  ingress {
    description = "Redis Access from Trusted App Nodes"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = var.app_nodes_ips
  }

  # --- OUTBOUND TRAFFIC (Allow All) ---
  egress {
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
# 2. PERSISTENT STORAGE (EBS VOLUME)
# Purpose: Save Grafana Dashboards and Redis Data if instance is recreated.
# ==============================================================================
resource "aws_ebs_volume" "state_data_volume" {
  availability_zone = "${var.region}a"
  size              = 10 # 10GB is enough for Metrics/Cache logs
  type              = "gp3"

  tags = {
    Name = "${var.project_name}-${var.environment}-persistence"
  }

  # CRITICAL: Prevent data loss on infrastructure updates
  lifecycle {
    prevent_destroy = true 
  }
}

# ==============================================================================
# 3. EC2 INSTANCE (STATE SERVER)
# Purpose: Hosting Redis, Prometheus, Grafana
# ==============================================================================
resource "aws_instance" "state_worker" {
  ami           = var.ami_id
  instance_type = "t3.large" 
  subnet_id     = var.public_subnet_id
  
  # STATIC INTERNAL IP
  private_ip    = "10.0.1.60" 
  
  vpc_security_group_ids = [aws_security_group.state_sg.id]

  # AUTOMATION: Re-creates instance if Cloud-Init script changes
  user_data_replace_on_change = true

  root_block_device {
    volume_size           = 25
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-server"
  }

  # --------------------------------------------------------------------------
  # AUTOMATED PROVISIONING SCRIPT (CLOUD-INIT)
  # --------------------------------------------------------------------------
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # A. INSTALL DOCKER & TOOLS
    dnf update -y
    dnf install -y docker git htop
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user

    # B. INSTALL DOCKER COMPOSE V2
    mkdir -p /usr/local/lib/docker/cli-plugins
    curl -SL https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

    # C. SWAP MEMORY CONFIGURATION (STABILITY FIX)
    # Adds 4GB Swap to prevent Prometheus OOM Kills
    dd if=/dev/zero of=/swapfile bs=128M count=32
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

    # D. MOUNT PERSISTENT DISK
    DATA_DISK="/dev/nvme1n1"
    MOUNT_POINT="/data"
    
    # Wait for EBS attachment
    sleep 20 

    if ! blkid $DATA_DISK; then
        mkfs -t xfs $DATA_DISK
    fi
    mkdir -p $MOUNT_POINT
    mount $DATA_DISK $MOUNT_POINT
    echo "$DATA_DISK $MOUNT_POINT xfs defaults,nofail 0 2" >> /etc/fstab
    
    # Create Persistent Directories
    mkdir -p $MOUNT_POINT/redis_data
    mkdir -p $MOUNT_POINT/prometheus_data
    mkdir -p $MOUNT_POINT/grafana_data
    mkdir -p $MOUNT_POINT/prometheus_config
    
    # --- CRITICAL PERMISSION FIX ---
    # Prevents "Permission Denied" errors for Redis/Grafana (UID 472/1000)
    chmod -R 777 $MOUNT_POINT

    # E. CREATE PROMETHEUS CONFIGURATION
    cat <<'PROMCONF' > $MOUNT_POINT/prometheus_config/prometheus.yml
    global:
      scrape_interval: 15s

    scrape_configs:
      - job_name: 'prometheus'
        static_configs:
          - targets: ['localhost:9090']
      # Placeholder for Node A/B targets
    PROMCONF

    # F. CREATE DOCKER COMPOSE FILE
    cat <<'COMPOSE' > /home/ec2-user/docker-compose.yml
    version: '3.8'
    services:
      redis:
        image: redis:alpine
        container_name: redis
        ports:
          - "6379:6379"
        # Redis Persistence Command
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
          - '--web.console.libraries=/usr/share/prometheus/console_libraries'
          - '--web.console.templates=/usr/share/prometheus/consoles'
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

    # G. START SERVICES
    cd /home/ec2-user
    # Re-apply permissions just in case
    chmod -R 777 $MOUNT_POINT
    docker compose up -d
    
    echo "SETUP COMPLETE: State Services Running."
  EOF
}

# ==============================================================================
# 4. VOLUME ATTACHMENT & ELASTIC IP
# ==============================================================================
resource "aws_volume_attachment" "state_ebs_att" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.state_data_volume.id
  instance_id = aws_instance.state_worker.id
}

resource "aws_eip" "state_eip" {
  domain = "vpc"
  tags = { Name = "${var.project_name}-${var.environment}-eip" }
  # PROTECT IP FROM DELETION
  lifecycle { prevent_destroy = true }
}

resource "aws_eip_association" "state_eip_assoc" {
  instance_id   = aws_instance.state_worker.id
  allocation_id = aws_eip.state_eip.id
}

output "public_ip" { value = aws_eip.state_eip.public_ip }