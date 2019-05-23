################################################################################
## Create VPC for Kafka
################################################################################

resource "aws_vpc" "main" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags {
    Name = "kafka.${var.domain}"
  }
}
