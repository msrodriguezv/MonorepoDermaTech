# infrastructure/terraform/modules/aws-networking/main.tf

# 1. Global Network (VPC)
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
  }
}

# 2. Internet Gateway (The door to the Internet)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# 3. Public Subnet (Where the Gateway with the Fixed IP will reside)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true # Required for instances here to access the internet
  availability_zone       = "${var.region}a"

  tags = {
    Name = "${var.project_name}-${var.environment}-public-subnet"
  }
}

# 4. Route Table for Public Subnet (Routing rules to access the internet)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

# 5. Associate the Route Table with the Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --- OUTPUTS ---
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the created VPC"
}

output "public_subnet_id" {
  value       = aws_subnet.public.id
  description = "The ID of the public subnet"
}