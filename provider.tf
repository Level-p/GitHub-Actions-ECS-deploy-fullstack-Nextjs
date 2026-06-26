provider "aws" {
  region = "eu-west-2"
}
terraform {
  backend "s3" {
    bucket = "varsitix-storage-bucket"
    key    = "infrastructure/terraform.tfstate"
    region = "eu-west-2" # Correct region
  }
}