##################################################
# DATA SOURCES
##################################################
data "aws_vpc" "peer" {
  id = "${var.vpc_peer}"
}

data "aws_availability_zones" "all" {}

##################################################
# INPUT VARIABLES
##################################################
variable "vpc_cidr" {}

variable "vpc_peer" {}

variable "name" {
  default = "kafka"
}

variable "centos_ami" {
    description = "Mapping ITERGO Custom CENTOS AMIs."
    default = {
        integration      = "ami-f5b9089a"
        prod       = "ami-da69d8b5"
    }
}

variable "cidr_all" {
  default = ["0.0.0.0/0"]
}

variable "keyname" {
  default = "kafka"
}

variable "domain" {}
