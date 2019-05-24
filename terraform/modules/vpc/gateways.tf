################################################################################
## Create Internet Gateway and NAT Gateway
################################################################################
resource "aws_internet_gateway" "public" {
  vpc_id = "${data.aws_vpc.main.id}"

  tags = {
    Name = "${var.name}-igw.${var.domain}"
  }
}

resource "aws_eip" "nateip" {
  depends_on = ["aws_internet_gateway.public"]
  vpc        = true
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = "${aws_eip.nateip.id}"
  subnet_id     = "${aws_subnet.public[0].id}"
  depends_on    = ["aws_internet_gateway.public"]
}
