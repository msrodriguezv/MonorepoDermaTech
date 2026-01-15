# ==============================================================================
# MODULE: AWS COMPUTE EVENTS
# Context: Kafka, RabbitMQ, Zookeeper, Mosquitto
# Purpose: Provisioning of the Message Broker Server with Persistent Storage
# ==============================================================================

# ==============================================================================
# 1. SECURITY GROUP (BASTION & INTERNAL ONLY)
# Purpose: Strict firewall rules. No public access except via Bastion/Nodes.
# ==============================================================================
resource "aws_security_group" "events_sg" {
  name        = "${var.project_name}-${var.environment}-sg"
  description = "Security Group for Events Infrastructure (Whitelisted)"
  vpc_id      = var.vpc_id

  # --- SSH ACCESS (Admin via Bastion) ---
  ingress {
    description = "SSH Access from QA Gateway"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.gateway_allowed_ip] 
  }

  # --- DATA PORTS (Kafka/RabbitMQ from App Nodes) ---
  ingress {
    description = "Data Traffic from Trusted App Nodes"
    from_port   = 0
    to_port     = 65535
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
# Purpose: Independent disk to save Kafka/Rabbit logs if instance is recreated.
# ==============================================================================
resource "aws_ebs_volume" "data_volume" {
  availability_zone = "${var.region}a"
  size              = 10
  type              = "gp3"

  tags = {
    Name = "${var.project_name}-${var.environment}-persistence"
  }

  lifecycle {
    prevent_destroy = true 
  }
}

# ==============================================================================
# 3. EC2 INSTANCE (EVENTS SERVER)
# Purpose: Hosting Kafka, Zookeeper, RabbitMQ, and MQTT
# ==============================================================================
resource "aws_instance" "worker" {
  ami           = var.ami_id
  instance_type = "t3.large" 
  subnet_id     = var.public_subnet_id
  private_ip    = var.private_ip_address
  
  vpc_security_group_ids = [aws_security_group.events_sg.id]
  user_data_replace_on_change = true

  root_block_device {
    volume_size           = 25
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-server"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # A. INSTALL DOCKER & TOOLS
    dnf update -y
    dnf install -y docker git htop nc
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user

    # B. INSTALL DOCKER COMPOSE V2
    mkdir -p /usr/local/lib/docker/cli-plugins
    curl -SL https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

    # C. SWAP MEMORY CONFIGURATION (STABILITY)
    # Essential for Java/Kafka memory spikes on T3 instances
    dd if=/dev/zero of=/swapfile bs=128M count=32
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

    # D. MOUNT PERSISTENT DISK & PERMISSIONS FIX
    DATA_DISK="/dev/nvme1n1"
    MOUNT_POINT="/data"
    
    # Grace period for EBS hot-plugging
    sleep 20 

    if ! blkid $DATA_DISK; then
        mkfs -t xfs $DATA_DISK
    fi
    mkdir -p $MOUNT_POINT
    mount $DATA_DISK $MOUNT_POINT
    echo "$DATA_DISK $MOUNT_POINT xfs defaults,nofail 0 2" >> /etc/fstab
    
    # Create Persistent Directories Structure
    mkdir -p $MOUNT_POINT/kafka $MOUNT_POINT/zookeeper $MOUNT_POINT/rabbitmq
    mkdir -p $MOUNT_POINT/mosquitto/config $MOUNT_POINT/mosquitto/data $MOUNT_POINT/mosquitto/log

    # --- GRANULAR OWNERSHIP FIX (Production Critical) ---
    # Prevents "Permission Denied" boot loops in containers
    # UID 1000: Default for Confluent/Kafka images
    # UID 999:  Default for Official RabbitMQ images
    chown -R 1000:1000 $MOUNT_POINT/kafka $MOUNT_POINT/zookeeper
    chown -R 999:999 $MOUNT_POINT/rabbitmq
    chown -R 1883:1883 $MOUNT_POINT/mosquitto

    # --- RABBITMQ SECURITY COMPLIANCE ---
    # Erlang cookies MUST have 600 permissions and proper ownership to boot
    touch $MOUNT_POINT/rabbitmq/.erlang.cookie
    chown 999:999 $MOUNT_POINT/rabbitmq/.erlang.cookie
    chmod 600 $MOUNT_POINT/rabbitmq/.erlang.cookie

    # E. CONFIGURE MOSQUITTO
    cat <<MQTTCFG > $MOUNT_POINT/mosquitto/config/mosquitto.conf
    persistence true
    persistence_location /mosquitto/data/
    log_dest file /mosquitto/log/mosquitto.log
    listener 1883
    allow_anonymous true
    listener 9001
    protocol websockets
    MQTTCFG

    # F. INJECT ENVIRONMENT VARIABLES
    PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)
    echo "KAFKA_PUBLIC_IP=$PUBLIC_IP" > /home/ec2-user/.env
    
    # G. AUTOMATE MASTER SSH KEY INJECTION
    # Ensures instant access for tunneling without manual console intervention
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3saMxMtMwZ1jRfnber/C2Qz/Y6qaKidbk9P3TPN1pE1rc2ayyqPGQcbDs9K6pSgwWWRn9e20kaeWc/K73kVo9F1biknB+P6CARX/0E2ybT4JuJMUH4cZ38ZDjT4brxC++OO+zqel5QubXajp6bslOzlXMYFCrexzFYXAQ5+0LtRPz4cw3KlFT2aFS6KCBsWxo3KsecCIYLfbU4l0qb72Jq8iIpujaCf2av3DkuE9BkFLUT52DsJ39paLfJYfSh48Qly42DM241oNawmZAdfPL92pctVxTCfmPnFuybnwksetaHMNi6OjH2LrIuySIxGIzuFKJHUqUZsQ5NdpFZqH/HOVgS4UhzVjkTSRAQuBpOUnjw5NTLjSfSfLkag29SK3QD2indvs+QZmJcLDWIXyJhSMFARX0nfOfuOhIyMrhAIG86Ekh2TgTCp5MwnmA/t2oqA4JRHVikPtmqO187AVe6wS/ZN0Nq8B8vHpZsF5xUFO/lZNIfxidIyzaprgiB09d02q7+9rr5g8ObRSUtkyOi8wkqo74ioWj4Vx1NRMVMb6FX4pGr6633Uw6Az4QFR8sVbZee/BYVgZVf//7t/SK/zHK7wzOhgIqRy2qkKgIJZHCgyF0eEr/zM2f/oM746WUl5aqQR7+W+SS6sHgGPjVxriQeRRAdjU+EyWWzKM0RQ==" >> /home/ec2-user/.ssh/authorized_keys

    # H. CREATE DOCKER COMPOSE FILE
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

    # I. START SERVICES
    cd /home/ec2-user
    docker compose up -d
    
    echo "SETUP COMPLETE: Persistent Stack Online"
  EOF
}

# ==============================================================================
# 4. VOLUME ATTACHMENT & ELASTIC IP
# ==============================================================================
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data_volume.id
  instance_id = aws_instance.worker.id
}

resource "aws_eip" "events_eip" {
  domain = "vpc"
  tags = { Name = "${var.project_name}-${var.environment}-eip" }
  lifecycle { prevent_destroy = true }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.worker.id
  allocation_id = aws_eip.events_eip.id
}

output "public_ip" { value = aws_eip.events_eip.public_ip }