################################################################################
## Create VPC Peering and Routes
################################################################################

# Create VPC Peering
resource "aws_vpc_peering_connection" "pc" {
  peer_vpc_id = "${var.vpc_peer}"
  vpc_id      = "${aws_vpc.main.id}"
  auto_accept = true
}

# Create a route table
resource "aws_route_table" "rt" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "${var.name}.${var.domain}"
  }
}

# Create a route
resource "aws_route" "r" {
  route_table_id            = "${aws_route_table.rt.id}"
  destination_cidr_block    = "${data.aws_vpc.peer.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.pc.id}"
}

################################################################################
## VPC Peering add routes on K8S VPC
################################################################################
data "aws_subnet_ids" "k8s" {
  vpc_id = "${var.vpc_peer}"

  tags {
    KubernetesCluster = "${var.name}.${var.domain}"
  }
}

data "aws_route_table" "k8s" {
  count     = "${length(data.aws_subnet_ids.k8s.ids)}"
  subnet_id = "${data.aws_subnet_ids.k8s.ids[count.index]}"
}

resource "aws_route" "k8s_rt" {
  count                     = "${length(distinct(data.aws_route_table.k8s.*.id))}"
  route_table_id            = "${element(distinct(data.aws_route_table.k8s.*.id), count.index)}"
  destination_cidr_block    = "${aws_vpc.main.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.pc.id}"
}
