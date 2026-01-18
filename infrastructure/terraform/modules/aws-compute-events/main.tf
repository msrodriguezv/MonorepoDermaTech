# ==============================================================================
# MODULE: AWS COMPUTE EVENTS
# Context: Kafka, RabbitMQ, Zookeeper
# Purpose: Messaging Server with INDESTRUCTIBLE IP (by ID) and Storage
# Instance: t3.large (8GB RAM) for JVM Heap stability
# ==============================================================================

# ==============================================================================
# 1. SECURITY GROUP
# ==============================================================================
resource "aws_security_group" "events_sg" {
  name        = "${var.project_name}-${var.environment}-sg"
  description = "Security Group for Events Infrastructure"
  vpc_id      = var.vpc_id

  # SSH Access from QA Bastion only
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.gateway_allowed_ip] 
  }

  # Messaging Ports (Internal Network)
  # 9092 (Kafka), 2181 (Zookeeper), 5672/15672 (Rabbit), 1883/9001 (MQTT)
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = var.app_nodes_ips
    description = "Allow App Nodes Full Access"
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
# 2. DATA SOURCE: ELASTIC IP (BLINDADO POR ID)
# We use the immutable Allocation ID. Terraform reads it, never destroys it.
# ==============================================================================
data "aws_eip" "events_eip" {
  id = var.eip_allocation_id
}

# ==============================================================================
# 3. PERSISTENT STORAGE (10GB)
# External volume that SURVIVES instance destruction.
# ==============================================================================
resource "aws_ebs_volume" "data_volume" {
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
# 4. EC2 INSTANCE (EVENTS SERVER)
# ==============================================================================
resource "aws_instance" "worker" {
  ami             = var.ami_id
  instance_type   = "t3.large" 
  subnet_id       = var.public_subnet_id
  key_name          = "vockey"
  
  # CRITICAL: Fixed Private IP (10.1.1.50)
  private_ip      = var.private_ip_address
  
  availability_zone = var.availability_zone
  
  vpc_security_group_ids      = [aws_security_group.events_sg.id]
  user_data_replace_on_change = true

  # ROOT VOLUME (System + Docker Images)
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
    dnf install -y docker git htop nc
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user

    # --- SWAP SETUP (4GB) ---
    # Critical for t3.large running Kafka + RabbitMQ + ZK
    dd if=/dev/zero of=/swapfile bs=128M count=32
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

    # --- PERSISTENT DISK MOUNTING ---
    DATA_DISK="/dev/nvme1n1"
    MOUNT_POINT="/data"
    
    # Wait for AWS to attach the volume
    while [ ! -b $DATA_DISK ]; do echo "Waiting for disk..."; sleep 5; done

    # Only format if it's a NEW disk (Protects Data)
    if ! blkid $DATA_DISK; then mkfs -t xfs $DATA_DISK; fi
    
    mkdir -p $MOUNT_POINT
    mount $DATA_DISK $MOUNT_POINT
    
    # Persist mount on reboot
    if ! grep -qs "$MOUNT_POINT" /etc/fstab; then
      echo "$DATA_DISK $MOUNT_POINT xfs defaults,nofail 0 2" >> /etc/fstab
    fi
    
    # --- DIRECTORIES & PERMISSIONS (CRITICAL) ---
    mkdir -p $MOUNT_POINT/kafka $MOUNT_POINT/zookeeper $MOUNT_POINT/rabbitmq
    mkdir -p $MOUNT_POINT/mosquitto/config $MOUNT_POINT/mosquitto/data $MOUNT_POINT/mosquitto/log

    # RabbitMQ (UID 999) - Kafka/ZK (UID 1000 for Confluent/Bitnami often varies, setting permissive or specific)
    # Using 1000:1000 for generic non-root users often used by containers
    chown -R 1000:1000 $MOUNT_POINT/kafka $MOUNT_POINT/zookeeper
    
    # RabbitMQ Official Image uses UID 999
    chown -R 999:999 $MOUNT_POINT/rabbitmq
    
    # Mosquitto Official Image uses UID 1883
    chown -R 1883:1883 $MOUNT_POINT/mosquitto
    
    # RabbitMQ Cookie Security (Prevents cluster startup failure)
    echo "DERMATECH_SECRET_COOKIE" > $MOUNT_POINT/rabbitmq/.erlang.cookie
    chown 999:999 $MOUNT_POINT/rabbitmq/.erlang.cookie
    chmod 600 $MOUNT_POINT/rabbitmq/.erlang.cookie

    # Mosquitto Config Injection
    cat <<MQTTCFG > $MOUNT_POINT/mosquitto/config/mosquitto.conf
    persistence true
    persistence_location /mosquitto/data/
    log_dest file /mosquitto/log/mosquitto.log
    listener 1883
    allow_anonymous true
    listener 9001
    protocol websockets
    MQTTCFG
    
    # Fix ownership of config file
    chown 1883:1883 $MOUNT_POINT/mosquitto/config/mosquitto.conf

    # Public IP Injection for Kafka Advertised Listeners
    PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)
    echo "KAFKA_PUBLIC_IP=$PUBLIC_IP" > /home/ec2-user/.env
    
    # Docker Compose File Generation
    cat <<COMPOSE > /home/ec2-user/docker-compose.yml
    version: '3.8'
    services:
      zookeeper:
        image: confluentinc/cp-zookeeper:7.5.0
        container_name: zookeeper
        environment:
          ZOOKEEPER_CLIENT_PORT: 2181
          ZOOKEEPER_TICK_TIME: 2000
        volumes:
          - $MOUNT_POINT/zookeeper:/var/lib/zookeeper/data
        restart: always

      kafka:
        image: confluentinc/cp-kafka:7.5.0
        container_name: kafka
        depends_on:
          zookeeper:
            condition: service_started
        ports:
          - "9092:9092"
        env_file: .env
        volumes:
          - $MOUNT_POINT/kafka:/var/lib/kafka/data
        environment:
          KAFKA_BROKER_ID: 1
          KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
          # Listeners: Internal (29092) and External (9092 via Public IP)
          KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://$${KAFKA_PUBLIC_IP}:9092
          KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
          KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
          KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
          KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true"
          KAFKA_HEAP_OPTS: "-Xmx2G -Xms2G"
        restart: always

      rabbitmq:
        image: rabbitmq:3-management
        container_name: rabbitmq
        ports:
          - "5672:5672"
          - "15672:15672"
        environment:
          RABBITMQ_DEFAULT_USER: admin
          RABBITMQ_DEFAULT_PASS: admin123
          RABBITMQ_ERLANG_COOKIE: "DERMATECH_SECRET_COOKIE"
        volumes:
          - $MOUNT_POINT/rabbitmq:/var/lib/rabbitmq
        restart: always

      mosquitto:
        image: eclipse-mosquitto
        container_name: mqtt
        ports:
          - "1883:1883"
          - "9001:9001"
        volumes:
          - $MOUNT_POINT/mosquitto/config:/mosquitto/config
          - $MOUNT_POINT/mosquitto/data:/mosquitto/data
          - $MOUNT_POINT/mosquitto/log:/mosquitto/log
        restart: always
    COMPOSE

    # Start Stack
    cd /home/ec2-user
    docker compose up -d
  EOF
}

# ==============================================================================
# 5. ATTACHMENTS & ASSOCIATIONS
# ==============================================================================
resource "aws_volume_attachment" "ebs_att" {
  device_name  = "/dev/sdf"
  volume_id    = aws_ebs_volume.data_volume.id
  instance_id  = aws_instance.worker.id
  force_detach = true
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.worker.id
  allocation_id = data.aws_eip.events_eip.id
}

output "public_ip" { 
  value = data.aws_eip.events_eip.public_ip 
}