# Declare the data source

data "aws_availability_zones" "all" {}


# EXISTING VPC data source
data "terraform_remote_state" "main" {
  backend = "s3"
  config = {

    bucket = "${var.vpc_state_bucket}"
    key    = "${var.vpc_state_key}"
    region = "eu-central-1"
  }
}

data "aws_vpc" "main" {
  filter {
     name = "tag-value"
     values = ["kafka.scigility"]
   }
   filter {
     name = "tag-key"
     values = ["Name"]
   }
}

data "aws_nat_gateway" "natgw" {
  vpc_id = "${data.aws_vpc.main.id}"
}

data "aws_instance" "bastion-host" {

  filter {
    name   = "tag:Name"
    values = ["bastion-kafka.development.scigility"]
  }
}
