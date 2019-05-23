##################################################
# DATA SOURCES
##################################################

data "aws_availability_zones" "all" {}

##################################################
# INPUT VARIABLES
##################################################
variable "vpc_cidr" {}

variable "name" {
  default = "kafka"
}

variable "cidr_all" {
  default = ["0.0.0.0/0"]
}

variable "keyname" {
  default = "kafka"
}

variable "domain" {}

variable "env" {}
