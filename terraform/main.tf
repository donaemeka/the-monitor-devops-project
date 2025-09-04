# ============================================================
# The Monitor DevOps Project - EC2 with Elastic IP
# ============================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

# ------------------------------------------------------------
# Random suffix for unique names
# ------------------------------------------------------------
resource "random_id" "suffix" {
  byte_length = 4
}

# ------------------------------------------------------------
# Use existing VPC and Subnet
# ------------------------------------------------------------
data "aws_vpc" "existing_vpc" {
  id = var.vpc_id
}

data "aws_subnet" "existing_subnet" {
  id = var.subnet_id
}

# ------------------------------------------------------------
# Security Group
# ------------------------------------------------------------
resource "aws_security_group" "monitor_sg" {
  name        = "monitor-sg-${random_id.suffix.hex}"
  description = "Security group for Monitor servers"
  vpc_id      = data.aws_vpc.existing_vpc.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
}

# ------------------------------------------------------------
# EC2 Instance
# ------------------------------------------------------------
resource "aws_instance" "monitor_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  subnet_id              = data.aws_subnet.existing_subnet.id
  vpc_security_group_ids = [aws_security_group.monitor_sg.id]
  associate_public_ip_address = false # We'll use Elastic IP

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
  }

  tags = {
    Name = "Monitor-Server"
  }
}

# ------------------------------------------------------------
# Elastic IP
# ------------------------------------------------------------
resource "aws_eip" "monitor_eip" {
  vpc = true
}

resource "aws_eip_association" "monitor_eip_assoc" {
  instance_id   = aws_instance.monitor_server.id
  allocation_id = aws_eip.monitor_eip.id
}

# ------------------------------------------------------------
# Output
# ------------------------------------------------------------
output "public_ip" {
  description = "Elastic IP of the EC2 instance"
  value       = aws_eip.monitor_eip.public_ip
}
