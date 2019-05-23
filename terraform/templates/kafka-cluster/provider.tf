provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket = "terraform.{{env}}.{{ aws.domain }}some.domain"
    key    = "{{env}}/{{build}}/terraform.tfstate"
    region = "eu-central-1"
    encrypt = true
  }
}
