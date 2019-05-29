# Declare the data source

data "aws_availability_zones" "all" {}


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


#data "aws_key_pair" "bastion_key" {
#
#  filter {
#    name   = "tag:Name"
#    values = ["bastion-key"]
#  }
#}
