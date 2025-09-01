# terraform/main.tf
# This VPC configuration is for the Monitor project
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2" # Using London region
}

# 1. Create a dedicated VPC (a virtual network)
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Main-VPC"
  }
}

# 2. Create an Internet Gateway (gives our VPC access to the internet)
resource "aws_internet_gateway" "main_gw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "Main-Internet-Gateway"
  }
}

# 3. Create a Route Table (defines the rules for network traffic)
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_gw.id
  }

  tags = {
    Name = "Public-Route-Table"
  }
}

# 4. Create a Subnet (a smaller segment of the VPC, in a specific data center)
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-2a"  # Availability zone for London region

  tags = {
    Name = "Public-Subnet"
  }
}

# 5. Associate the Route Table with the Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route.id
}

# 6. Now create the Security Group INSIDE the new VPC
resource "aws_security_group" "monitor_sg" {
  name        = "monitor-sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.main_vpc.id

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

# 7. Create the EC2 instance in the new public subnet
resource "aws_instance" "monitor_server" {
  # Ubuntu 24.04 LTS AMI for eu-west-2 (London)
  ami           = "ami-0379821d182aac933" # Use the exact AMI ID from your console
  instance_type = "t2.micro"
  key_name      = "monitor-key" # Ensure this key exists in eu-west-2

  subnet_id                   = aws_subnet.public_subnet.id
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