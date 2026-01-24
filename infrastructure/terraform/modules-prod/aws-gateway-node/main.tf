# ==============================================================================
# MODULE: AWS GATEWAY NODE
# Purpose: Public Entry Point (Bastion + Nginx Reverse Proxy Bridge)
# Cost Optimization: t3.medium (Fits within $45 budget for 15 days)
# Storage: 
#   - Root: 25GB (Required for Docker Images/Logs)
#   - External: 10GB (Strict Data Persistence)
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

  # Outbound Rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${var.environment}-gateway-sg" }
}

# ==============================================================================
# 3. DATA SOURCE: ELASTIC IP (SHIELDED BY ID)
# ==============================================================================
data "aws_eip" "gateway_eip" {
  id = var.eip_allocation_id
}

# ==============================================================================
# 4. EBS VOLUME (EXTERNAL PERSISTENCE 10GB)
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
# 5. EC2 INSTANCE (BASTION & PROXY)
# ==============================================================================
resource "aws_instance" "gateway" {
  ami           = var.ami_id
  instance_type = "t3.medium"
  subnet_id     = var.public_subnet_id
  key_name      = aws_key_pair.deployer.key_name
  private_ip    = var.bastion_private_ip
  availability_zone = var.availability_zone
  vpc_security_group_ids = [aws_security_group.gateway_sg.id]
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 25
    volume_type = "gp3"
    encrypted   = true
    tags = {
      Name = "${var.project_name}-${var.environment}-gateway-root"
    }
  }

  # ----------------------------------------------------------------------------
  # USER DATA: HYBRID BRIDGE CONFIGURATION (PROD)
  # ----------------------------------------------------------------------------
  user_data = <<-EOF
              #!/bin/bash
              set -e
              
              # --- INSTALLATION ---
              dnf update -y
              dnf install -y nginx git docker htop
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              
              # --- MOUNT PERSISTENT DISK (10GB) ---
              DATA_DISK="/dev/nvme1n1"
              MOUNT_POINT="/mnt/data"
              
              while [ ! -b $DATA_DISK ]; do echo "Waiting for disk..."; sleep 5; done
              if ! blkid $DATA_DISK; then mkfs -t ext4 $DATA_DISK; fi
              
              mkdir -p $MOUNT_POINT
              mount $DATA_DISK $MOUNT_POINT
              
              if ! grep -qs "$MOUNT_POINT" /etc/fstab; then
                echo "$DATA_DISK $MOUNT_POINT ext4 defaults,nofail 0 2" >> /etc/fstab
              fi

              # --- NGINX CONFIGURATION (THE BRIDGE) ---
              # Fixed IP (Bastion) -> ALB DNS -> Backend Nodes
              
              cat <<EOT > /etc/nginx/nginx.conf
              user nginx;
              worker_processes auto;
              error_log /var/log/nginx/error.log;
              pid /run/nginx.pid;
              
              events { worker_connections 1024; }
              
              http {
                  include /etc/nginx/mime.types;
                  default_type application/octet-stream;
                  
                  # UPSTREAM: Points to the AWS Application Load Balancer
                  upstream aws_alb {
                      server ${var.alb_dns_name};
                  }
                  
                  server {
                      listen 80;
                      server_name _;
                      
                      location /health {
                          access_log off;
                          return 200 "OK - PROD Bridge Active\n";
                          add_header Content-Type text/plain;
                      }
                      
                      location / {
                          proxy_pass http://aws_alb;
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
              
              systemctl start nginx
              systemctl enable nginx
              echo "Gateway Bridge Setup Complete"
              EOF

  tags = { Name = "${var.project_name}-${var.environment}-gateway" }
}

# ==============================================================================
# 6. ATTACHMENTS & ASSOCIATIONS
# ==============================================================================
resource "aws_volume_attachment" "gateway_data_attach" {
  device_name  = "/dev/sdf"
  volume_id    = aws_ebs_volume.gateway_data.id
  instance_id  = aws_instance.gateway.id
  force_detach = true 
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.gateway.id
  allocation_id = data.aws_eip.gateway_eip.id
}

output "final_public_ip" { 
  value = data.aws_eip.gateway_eip.public_ip 
}

output "bastion_private_ip" { 
  value = aws_instance.gateway.private_ip 
}