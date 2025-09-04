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

  # ADDED: Backend configuration for remote state
  backend "s3" {
    bucket         = "my-new-terraform-bucket"
    key            = "monitor-project/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-west-2"
}

# ------------------------------------------------------------
# Variable Definitions - ADDED: All required variables
# ------------------------------------------------------------
variable "vpc_id" {
  description = "The ID of the existing VPC"
  type        = string
}

variable "subnet_id" {
  description = "The ID of the existing subnet"
  type        = string
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0d729d2846a86a9e7" # Ubuntu 22.04 LTS in eu-west-2
}

variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "The name of the existing EC2 key pair"
  type        = string
}

variable "root_volume_size" {
  description = "The size of the root volume in GB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "The type of the root volume"
  type        = string
  default     = "gp2"
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
# Security Group - IMPROVED: Added more ports for monitoring stack
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
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
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

  ingress {
    description = "Allow Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Node Exporter"
    from_port   = 9100
    to_port     = 9100
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
    encrypted   = true # ADDED: Encryption for security
  }

  # ADDED: User data for basic setup
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3
              EOF

  tags = {
    Name = "Monitor-Server-${random_id.suffix.hex}"
  }
}

# ------------------------------------------------------------
# Elastic IP
# ------------------------------------------------------------
resource "aws_eip" "monitor_eip" {
  vpc = true
  
  tags = {
    Name = "Monitor-EIP-${random_id.suffix.hex}"
  }
}

resource "aws_eip_association" "monitor_eip_assoc" {
  instance_id   = aws_instance.monitor_server.id
  allocation_id = aws_eip.monitor_eip.id
}

# ------------------------------------------------------------
# Outputs - ADDED: More useful outputs
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

output "ssh_connection" {
  description = "SSH connection command"
  value       = "ssh -i monitor-key.pem ubuntu@${aws_eip.monitor_eip.public_ip}"
}