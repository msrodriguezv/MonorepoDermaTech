# infrastructure/terraform/modules/aws-compute-node/main.tf

# 1. Security Group for Workers
resource "aws_security_group" "compute_sg" {
  name        = "${var.project_name}-${var.environment}-compute-sg"
  description = "Security group for Worker Nodes"
  vpc_id      = var.vpc_id

  # SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Application & Infra Ports (Open range for internal comms via public IP)
  # Ideally, this should be restricted to Gateway IPs only.
  ingress {
    from_port   = 3000
    to_port     = 10000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. EC2 Instance (High Performance)
resource "aws_instance" "worker" {
  ami                    = var.ami_id
  instance_type          = "t3.medium" # 4GB RAM required for Kafka/NestJS
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.compute_sg.id]

  root_block_device {
    volume_size = 25        
    volume_type = "gp3"     # Disco SSD de propósito general 
    delete_on_termination = true
  }

  # Install Docker & Compose
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y docker git
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              
              # Install Docker Compose V2
              mkdir -p /usr/local/lib/docker/cli-plugins
              curl -SL https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
              chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
              
              # App Directory
              mkdir -p /home/ec2-user/app
              chown -R ec2-user:ec2-user /home/ec2-user/app
              EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-worker"
  }
}

output "public_ip" {
  value = aws_instance.worker.public_ip
}