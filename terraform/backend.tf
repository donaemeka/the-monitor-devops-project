terraform {
  backend "s3" {
    bucket         = "my-terraform-state-eu-west-2"
    key            = "monitor-project/terraform.tfstate"
    region         = "eu-west-2"  # Your preferred region
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}