variable "env" {
}

variable "kafka_ec2_type" {
}

variable "name" {
  default = "kafka"
}

variable "stack_offset" {
   description = "Subnet cidrs increment for each environment DEV=0 TEST=1"
}


variable "nr_zk_nodes" {
  default = "3"
}

variable "nr_kafka_nodes" {
  default = "3"
}
variable "mirrormaker" {
  default = false
}

variable "ami" {
}

variable "domain" {
}

variable "cidr_block_all" {
  default = ["0.0.0.0/0"]
}

variable "keyname" {
  default = "gk-paris"
}

variable "kafka-disksize" {
   default =   "20"
}

variable "kafka-disktype" {
   default =   "gp2"
}

variable "prevent_destroy_ebs" {
   default =   "true"
}

variable "ssh_user" {
  default = "centos"
}
variable "bastion_user" {
   default =   "centos"
}

variable "ssl_zipfile" {
   default =   "ssl.zip"
}
variable "vpc_state_bucket" {
}

variable "vpc_state_key" {
}
