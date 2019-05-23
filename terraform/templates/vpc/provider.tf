provider "aws" {
  region = "eu-west-3"
}

resource "aws_s3_bucket" "terraform-state-storage-s3" {
    bucket = "terraform-kafka.{{env}}.{{ domain }}"
    versioning {
      enabled = true
    }
    lifecycle {
      prevent_destroy = true
    }
    tags {
      Name = "S3 Remote Terraform State Store"
      Customer = "Scigility"
      Project  = "Kafka-AWS-internal"
      Requestor = "Gerd"
    }
}

terraform {
  backend "s3" {
    bucket = "terraform-kafka.{{env}}.{{ domain }}"
    key    = "{{env}}/vpc/terraform.tfstate"
    region = "eu-west-3"
    encrypt = true
  }
}
