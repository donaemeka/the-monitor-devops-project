# variables.tf
variable "ami_id" {
  description = "The AMI ID for the EC2 instance (Amazon Linux 2)"
  type        = string
  default     = "ami-0aa7d40eeae50c9a9"  # Amazon Linux 2 in us-east-1
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