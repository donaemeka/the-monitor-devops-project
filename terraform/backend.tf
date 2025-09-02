terraform {
  backend "s3" {
    bucket         = "my-new-terraform-bucket"  # ← Match this
    key            = "monitor-project/terraform.tfstate"
    region         = "eu-west-2" 
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}