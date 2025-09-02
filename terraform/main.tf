# Infrastructure for The Monitor DevOps Project
# Using existing VPC: vpc-0280c538c474724ba

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

# Use the EXISTING VPC that you already have
data "aws_vpc" "existing_vpc" {
  id = "vpc-0280c538c474724ba" # Your existing VPC ID
}

# Use the EXISTING Subnet that you already have
data "aws_subnet" "existing_subnet" {
  id = "subnet-0955441f00fafb2e7" # You need to find the actual subnet ID from your VPC
}

# Create the Security Group INSIDE the existing VPC
resource "aws_security_group" "monitor_sg" {
  name        = "monitor-sg123"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = data.aws_vpc.existing_vpc.id # Use the existing VPC

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Monitor-SG"
  }
}

# Create the EC2 instance in the EXISTING subnet
resource "aws_instance" "monitor_server" {
  ami           = "ami-0379821d182aac933" # Ubuntu 22.04 LTS for eu-west-2
  instance_type = "t2.micro"
  key_name      = "monitor-key" # Make sure this key exists in eu-west-2

  subnet_id                   = data.aws_subnet.existing_subnet.id # Use existing subnet
  vpc_security_group_ids      = [aws_security_group.monitor_sg.id]
  associate_public_ip_address = true 

  tags = {
    Name = "Monitor-Server"
  }
}

# Output the public IP address of the instance
output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.monitor_server.public_ip
}

