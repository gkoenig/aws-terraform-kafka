provider "aws" {
  region = "eu-west-3"
}

terraform {
  backend "local" {
    path = "${path.module}/../terraform.tfstate"
  }
}
