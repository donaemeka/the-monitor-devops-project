terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "monitor-project/terraform.tfstate"
    region = "us-east-1"
  }
}