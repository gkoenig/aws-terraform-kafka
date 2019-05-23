provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket = "terraform.development.scigilitysome.domain"
    key    = "development/dev-00/terraform.tfstate"
    region = "eu-central-1"
    encrypt = true
  }
}
