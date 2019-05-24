################################################################################
## One Subnet per Availability Zone
################################################################################
resource "aws_subnet" "main" {
  count                   = "${length(data.aws_availability_zones.all.names)}"
  vpc_id                  = "${data.aws_vpc.main.id}"
  cidr_block              = "${cidrsubnet(data.aws_vpc.main.cidr_block, 8, length(data.aws_availability_zones.all.names) * var.stack_offset + count.index)}"
  availability_zone       = "${element(data.aws_availability_zones.all.names, count.index)}"
  map_public_ip_on_launch = false

  tags ={
    Name = "${var.env}.${var.domain}-${count.index}"
  }
}


/***************************************************
* ASSOCIATE SUBNETS TO ROUTE TABLE
****************************************************/
resource "aws_route_table" "rtb" {
  vpc_id = "${data.terraform_remote_state.main.vpc_id}"

  tags ={
    Name = "${var.name}-internal-natgw"
  }
}

resource "aws_route" "rt" {
  route_table_id         = "${aws_route_table.rtb.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${data.terraform_remote_state.main.natgw_id}"
}

# Route to Kubernetes VPC
resource "aws_route" "rt_peer" {
  route_table_id         = "${aws_route_table.rtb.id}"
  destination_cidr_block = "${data.aws_vpc.peer.cidr_block}"
  vpc_peering_connection_id = "${data.terraform_remote_state.main.peering_connection_id}"
}

resource "aws_route_table_association" "rta_public" {
  count          = "${length(data.aws_availability_zones.all.names)}"
  subnet_id      = "${element(aws_subnet.main.*.id,count.index)}"
  route_table_id = "${aws_route_table.rtb.id}"
}


################################################################################
## Security Groups
################################################################################

#--------------------------
# Security Group Kafka
#--------------------------
resource "aws_security_group" "kafka" {
  name        = "${var.env}-kafka"
  description = "Kafka Security Group"
  vpc_id      = "${data.terraform_remote_state.main.vpc_id}"

  tags ={
    Name = "${var.env}-kafka"
  }
}

// Allow any internal network flow.
resource "aws_security_group_rule" "kfk_ingress_any_any_self" {
  security_group_id = "${aws_security_group.kafka.id}"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  self              = true
  type              = "ingress"
}

// Allow TCP:22 (SSH)
resource "aws_security_group_rule" "kfk_ingress_tcp_22_cidr" {
  security_group_id = "${aws_security_group.kafka.id}"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${data.terraform_remote_state.main.bastion_ip_priv}/32" ,"${data.aws_vpc.peer.cidr_block}","${data.aws_vpc.main.cidr_block}"]
  type              = "ingress"
}

// Allow TCP:6667 (Kafka broker 0.8.1.x)
# resource "aws_security_group_rule" "kfk_ingress_tcp_6667_cidr" {
#   security_group_id = "${aws_security_group.kafka.id}"
#   from_port         = 6667
#   to_port           = 6667
#   protocol          = "tcp"
#   cidr_blocks       = "${var.cidr_block_all}"
#   type              = "ingress"
# }

// Allow TCP:9092 (Kafka broker 0.8.2+)
resource "aws_security_group_rule" "kfk_ingress_tcp_9092_cidr" {
  security_group_id = "${aws_security_group.kafka.id}"
  from_port         = 9092
  to_port           = 9092
  protocol          = "tcp"
  cidr_blocks       = "${var.cidr_block_all}"
  type              = "ingress"
}
// Allow TCP:9093 (Kafka SASL)
resource "aws_security_group_rule" "kfk_ingress_tcp_9093_cidr" {
  security_group_id = "${aws_security_group.kafka.id}"
  from_port         = 9093
  to_port           = 9093
  protocol          = "tcp"
  cidr_blocks       = "${var.cidr_block_all}"
  type              = "ingress"
}

// Allow TCP:9094 (Kafka SSL)
resource "aws_security_group_rule" "kfk_ingress_tcp_9094_cidr" {
  security_group_id = "${aws_security_group.kafka.id}"
  from_port         = 9094
  to_port           = 9094
  protocol          = "tcp"
  cidr_blocks       = "${var.cidr_block_all}"
  type              = "ingress"
}
// Allow TCP:9095 (Kafka SASL_SSL)
resource "aws_security_group_rule" "kfk_ingress_tcp_9095_cidr" {
  security_group_id = "${aws_security_group.kafka.id}"
  from_port         = 9095
  to_port           = 9095
  protocol          = "tcp"
  cidr_blocks       = "${var.cidr_block_all}"
  type              = "ingress"
}

// Allow TCP:7071(Prometheus Exporter)
resource "aws_security_group_rule" "kfk_ingress_tcp_7071_cidr" {
  security_group_id = "${aws_security_group.kafka.id}"
  from_port         = 7071
  to_port           = 7071
  protocol          = "tcp"
  cidr_blocks       = "${var.cidr_block_all}"
  type              = "ingress"
}

// Allow TCP:ALL to Bastion Net (ALL)
resource "aws_security_group_rule" "kfk_egress_allow_all_bastion" {
  security_group_id = "${aws_security_group.kafka.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "egress"
}
#--------------------------
# Security Group Zookeeper
#--------------------------
resource "aws_security_group" "zookeeper" {
  name        = "${var.env}-zookeeper"
  description = "Zookeeper Security Group"
  vpc_id      = "${data.aws_vpc.main.id}"

  tags ={
    Name = "${var.env}-zookeeper"
  }
}

// Allow any internal network flow.
resource "aws_security_group_rule" "zk_ingress_any_any_self" {
  security_group_id = "${aws_security_group.zookeeper.id}"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  self              = true
  type              = "ingress"
}

// Allow TCP:22 (SSH)
resource "aws_security_group_rule" "zk_ingress_tcp_22_cidr" {
  security_group_id = "${aws_security_group.zookeeper.id}"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${data.terraform_remote_state.main.bastion_ip_priv}/32" ,"${data.aws_vpc.peer.cidr_block}","${data.aws_vpc.main.cidr_block}"]
  type              = "ingress"
}

// Allow TCP:2181 (Zookeeper)
resource "aws_security_group_rule" "zk_ingress_tcp_2181_cidr" {
  security_group_id = "${aws_security_group.zookeeper.id}"
  from_port         = 2181
  to_port           = 2181
  protocol          = "tcp"
  cidr_blocks       = "${var.cidr_block_all}"
  type              = "ingress"
}

// Allow TCP:2888 (Zookeeper)
resource "aws_security_group_rule" "zk_ingress_tcp_2888_cidr" {
  security_group_id = "${aws_security_group.zookeeper.id}"
  from_port         = 2888
  to_port           = 2888
  protocol          = "tcp"
  cidr_blocks       = "${var.cidr_block_all}"
  type              = "ingress"
}

// Allow TCP:7071(Prometheus Exporter)
resource "aws_security_group_rule" "zk_ingress_tcp_7071_cidr" {
  security_group_id = "${aws_security_group.zookeeper.id}"
  from_port         = 7071
  to_port           = 7071
  protocol          = "tcp"
  cidr_blocks       = "${var.cidr_block_all}"
  type              = "ingress"
}
// Allow TCP:7199 (JMX)
# resource "aws_security_group_rule" "zk_ingress_tcp_7199_cidr" {
#   security_group_id = "${aws_security_group.zookeeper.id}"
#   from_port         = 7199
#   to_port           = 7199
#   protocol          = "tcp"
#   cidr_blocks       = "${var.cidr_block_all}"
#   type              = "ingress"
# }

// Allow TCP:3888 (Zookeper)
resource "aws_security_group_rule" "zk_ingress_tcp_3888_cidr" {
  security_group_id = "${aws_security_group.zookeeper.id}"
  from_port         = 3888
  to_port           = 3888
  protocol          = "tcp"
  cidr_blocks       = "${var.cidr_block_all}"
  type              = "ingress"
}

// Allow TCP:ALL Internal (ALL)
resource "aws_security_group_rule" "zk_egress_allow_all_internal" {
  security_group_id = "${aws_security_group.zookeeper.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks              = ["0.0.0.0/0"]
  type              = "egress"
}
