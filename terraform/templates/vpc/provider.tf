provider "aws" {
  region = "eu-west-3"
}

terraform {
  backend "s3" {
    bucket = "terraform.{{env}}.{{ aws.domain }}"
    key    = "{{env}}/vpc/terraform.tfstate"
    region = "eu-west-3"
    encrypt = true
  }
}
