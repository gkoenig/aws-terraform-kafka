provider "aws" {
  region = "eu-west-3"
}

terraform {
  backend "s3" {
    bucket = "terraform.development.scigility"
    key    = "development/vpc/terraform.tfstate"
    region = "eu-west-3"
    encrypt = true
  }
}
