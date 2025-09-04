# ============================================================
# Variables for The Monitor DevOps Project
# ============================================================

variable "vpc_id" {
  description = "Existing VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Existing Subnet ID"
  type        = string
}

variable "ami_id" {
  description = "AMI for EC2"
  type        = string
  default     = "ami-046c2381f11878233" # Ubuntu 22.04 LTS
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Existing SSH key in AWS"
  type        = string
}

variable "root_volume_size" {
  description = "Root volume size (GB)"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Root volume type"
  type        = string
  default     = "gp3"
}
