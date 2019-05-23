# Declare the data source

data "aws_availability_zones" "all" {}


# EXISTING VPC data source
data "terraform_remote_state" "main" {
  backend = "s3"
  config {

    bucket = "${var.vpc_state_bucket}"
    key    = "${var.vpc_state_key}"
    region = "eu-central-1"
  }
}

data "aws_vpc" "main" {
  id = "${data.terraform_remote_state.main.vpc_id}"
}

data "aws_vpc" "peer" {
  id = "${data.terraform_remote_state.main.vpc_peer_id}"
}

