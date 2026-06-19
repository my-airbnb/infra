terraform {
  backend "s3" {
    bucket = "my-airbnb-tfstate-CHANGE_ME"
    key = "infra/terraform.tfstate"
    region = "eu-west-1"
    encrypt = true
  }
}