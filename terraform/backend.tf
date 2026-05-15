terraform {
  backend "s3" {
    bucket = "my-airbnb-terraform-state"
    key = "infra/terraform.tfstate"
    region = "eu-west-1"
    encrypt = true
  }
}