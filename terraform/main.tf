# ============================================================
# The Monitor DevOps Project - EC2 with Elastic IP
# ============================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-state-426333731292-us-east-1"
    key            = "monitor-project/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

# ------------------------------------------------------------
# Create NEW VPC and Subnet
# ------------------------------------------------------------
resource "aws_vpc" "monitor_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Monitor-VPC"
  }
}

resource "aws_subnet" "monitor_subnet" {
  vpc_id                  = aws_vpc.monitor_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Monitor-Subnet"
  }
}

resource "aws_internet_gateway" "monitor_igw" {
  vpc_id = aws_vpc.monitor_vpc.id

  tags = {
    Name = "Monitor-IGW"
  }
}

resource "aws_route_table" "monitor_rt" {
  vpc_id = aws_vpc.monitor_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.monitor_igw.id
  }

  tags = {
    Name = "Monitor-RouteTable"
  }
}

resource "aws_route_table_association" "monitor_rta" {
  subnet_id      = aws_subnet.monitor_subnet.id
  route_table_id = aws_route_table.monitor_rt.id
}

# ------------------------------------------------------------
# Security Group - COMPLETE VERSION
# ------------------------------------------------------------
resource "aws_security_group" "monitor_sg" {
  name        = "monitor-sg"
  description = "Security group for Monitor servers"
  vpc_id      = aws_vpc.monitor_vpc.id

  # SSH access
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access
  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Grafana access
  ingress {
    description = "Allow Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Prometheus access
  ingress {
    description = "Allow Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Node Exporter access
  ingress {
    description = "Allow Node Exporter"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Caddy admin access
  ingress {
    description = "Allow Caddy admin"
    from_port   = 2019
    to_port     = 2019
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Monitor-SG"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ------------------------------------------------------------
# EC2 Instance - FIXED FOR AMAZON LINUX 2
# ------------------------------------------------------------
resource "aws_instance" "monitor_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  subnet_id              = aws_subnet.monitor_subnet.id
  vpc_security_group_ids = [aws_security_group.monitor_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    encrypted   = true
  }

  # Amazon Linux 2 compatible user data
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3
              EOF

  tags = {
    Name = "Monitor-Server"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [ami]
  }
}

# ------------------------------------------------------------
# Elastic IP
# ------------------------------------------------------------
resource "aws_eip" "monitor_eip" {
  domain = "vpc"
  
  tags = {
    Name = "Monitor-EIP"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_eip_association" "monitor_eip_assoc" {
  instance_id   = aws_instance.monitor_server.id
  allocation_id = aws_eip.monitor_eip.id
}

# ------------------------------------------------------------
# Outputs
# ------------------------------------------------------------
output "public_ip" {
  description = "Elastic IP of the EC2 instance"
  value       = aws_eip.monitor_eip.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.monitor_server.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.monitor_sg.id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.monitor_vpc.id
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = aws_subnet.monitor_subnet.id
}

output "ssh_connection" {
  description = "SSH connection command"
  value = "ssh -i donatus.pem ec2-user@${aws_eip.monitor_eip.public_ip}"
}