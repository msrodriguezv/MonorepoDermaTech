# ==============================================================================
# MODULE: AWS GATEWAY NODE
# Purpose: Public Entry Point (Bastion + Nginx Reverse Proxy)
# Cost Optimization: t3.medium (Fits within $45 budget for 15 days)
# Storage: 
#   - Root: 25GB (Required for Docker Images/Logs)
#   - External: 10GB (Strict Data Persistence)
# ==============================================================================

# ==============================================================================
# 1. SECURITY GROUP
# ==============================================================================
resource "aws_security_group" "gateway_sg" {
  name        = "${var.project_name}-${var.environment}-gateway-sg"
  description = "Security group for API Gateway Nginx and Bastion"
  vpc_id      = var.vpc_id

  # Public HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Public HTTP"
  }
   
  # Public HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Public HTTPS"
  }

  # Admin SSH (Bastion Access)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH Administration"
  }

  # Outbound Rule (Allow all traffic out)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${var.environment}-gateway-sg" }
}

# ==============================================================================
# 2. DATA SOURCE: ELASTIC IP (SHIELDED BY ID)
# We use the immutable Allocation ID. Terraform reads it, never destroys it.
# ==============================================================================
data "aws_eip" "gateway_eip" {
  id = var.eip_allocation_id
}

# ==============================================================================
# 3. EBS VOLUME (EXTERNAL PERSISTENCE 10GB)
# This volume survives instance destruction (prevent_destroy enabled)
# ==============================================================================
resource "aws_ebs_volume" "gateway_data" {
  availability_zone = var.availability_zone
  size              = 10
  type              = "gp3"
  encrypted         = true
   
  tags = {
    Name      = "${var.project_name}-${var.environment}-gateway-data"
    ManagedBy = "terraform"
  }
   
  lifecycle {
    prevent_destroy = true # CRITICAL: PROTECTS PERSISTENT DATA
  }
}

# ==============================================================================
# 4. EC2 INSTANCE (BASTION & PROXY)
# ==============================================================================
resource "aws_instance" "gateway" {
  ami               = var.ami_id
   
  # BUDGET CORRECTION: t3.medium ($0.0416/hr) vs t3.large ($0.0832/hr)
  # t3.medium (2 vCPU, 4GB RAM) is sufficient for Nginx/Bastion duties.
  instance_type     = "t3.medium"
   
  subnet_id         = var.public_subnet_id
  key_name          = "vockey"
   
  # CRITICAL: Fixed Private IP for Peering Routes
  private_ip        = var.bastion_private_ip
   
  # Ensure instance is in the same AZ as the EBS Volume
  availability_zone = var.availability_zone
   
  vpc_security_group_ids      = [aws_security_group.gateway_sg.id]
  user_data_replace_on_change = true

  # ROOT VOLUME CONFIGURATION (25GB Base for Docker)
  # This volume IS destroyed with the instance.
  root_block_device {
    volume_size = 25
    volume_type = "gp3"
    encrypted   = true
    tags = {
      Name = "${var.project_name}-${var.environment}-gateway-root"
    }
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e
              
              # --- INSTALLATION ---
              dnf update -y
              dnf install -y nginx git docker htop
              systemctl start nginx
              systemctl enable nginx
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              
              # --- MOUNT PERSISTENT DISK (10GB) ---
              # On Nitro Instances (t3 family), /dev/sdf maps to /dev/nvme1n1
              DATA_DISK="/dev/nvme1n1"
              MOUNT_POINT="/mnt/data"
              
              # Wait for disk attachment
              while [ ! -b $DATA_DISK ]; do echo "Waiting for disk..."; sleep 5; done

              # Only format if no filesystem exists (Protects Data on Re-creation)
              if ! blkid $DATA_DISK; then mkfs -t ext4 $DATA_DISK; fi
              
              mkdir -p $MOUNT_POINT
              mount $DATA_DISK $MOUNT_POINT
              
              # Add to fstab for automatic mounting on reboot
              if ! grep -qs "$MOUNT_POINT" /etc/fstab; then
                echo "$DATA_DISK $MOUNT_POINT ext4 defaults,nofail 0 2" >> /etc/fstab
              fi

              # --- NGINX CONFIGURATION (Reverse Proxy) ---
              cat <<EOT > /etc/nginx/nginx.conf
              user nginx;
              worker_processes auto;
              error_log /var/log/nginx/error.log;
              pid /run/nginx.pid;
              
              events { worker_connections 1024; }
              
              http {
                  include /etc/nginx/mime.types;
                  default_type application/octet-stream;
                  
                  # Upstream to App Nodes (Internal IPs)
                  # Traffic flows through Peering Connections
                  upstream backend_cluster {
                      least_conn;
                      # Node A (Account 04)
                      server 10.3.1.10:3000 max_fails=3 fail_timeout=30s;
                      # Node B (Account 05)
                      server 10.4.1.10:3000 max_fails=3 fail_timeout=30s;
                  }
                  
                  server {
                      listen 80;
                      server_name _;
                      
                      # Health Check Endpoint
                      location /health {
                          access_log off;
                          return 200 "OK\n";
                          add_header Content-Type text/plain;
                      }
                      
                      # Main Proxy Logic
                      location / {
                          proxy_pass http://backend_cluster;
                          proxy_set_header Host \$host;
                          proxy_set_header X-Real-IP \$remote_addr;
                          proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                          
                          proxy_connect_timeout 60s;
                          proxy_send_timeout 60s;
                          proxy_read_timeout 60s;
                      }
                  }
              }
              EOT
              
              systemctl restart nginx
              echo "Gateway Setup Complete"
              EOF

  tags = { Name = "${var.project_name}-${var.environment}-gateway" }
}

# ==============================================================================
# 5. ATTACHMENTS & ASSOCIATIONS
# ==============================================================================
resource "aws_volume_attachment" "gateway_data_attach" {
  device_name  = "/dev/sdf"
  volume_id    = aws_ebs_volume.gateway_data.id
  instance_id  = aws_instance.gateway.id
   
  # Force detach ensures terraform can re-attach volume if instance is recreated
  force_detach = true 
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.gateway.id
  allocation_id = data.aws_eip.gateway_eip.id
}

# ==============================================================================
# 6. OUTPUTS
# ==============================================================================
output "final_public_ip" { 
  value = data.aws_eip.gateway_eip.public_ip 
}

output "bastion_private_ip" { 
  value = aws_instance.gateway.private_ip 
}