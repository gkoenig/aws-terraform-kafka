################################################################################
## Subnet and Route Tables
################################################################################

# Create Public Subnet
resource "aws_subnet" "public" {
  count             = 1
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${cidrsubnet(var.vpc_cidr,8,250+count.index)}"
  availability_zone = "${element(data.aws_availability_zones.all.names, 1)}"

  tags = {
    Name = "public.kafka.${var.domain}"
  }

  lifecycle {
    create_before_destroy = true
  }

  map_public_ip_on_launch = true
}

# Create Public Route
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"

  # Route to Internet
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.public.id}"
  }

  tags = {
    Name = "igw.kafka.${var.domain}"
  }
}

# Associate Route to Subnet
resource "aws_route_table_association" "public" {
  count          = 1
  subnet_id      = "${aws_subnet.public[0].id}"
  route_table_id = "${aws_route_table.public.id}"
}
