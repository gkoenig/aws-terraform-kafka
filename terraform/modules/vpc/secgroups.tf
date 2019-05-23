################################################################################
## Security Groups
################################################################################

resource "aws_security_group" "bastion" {
  name        = "bastion.kafka.${var.domain}"
  description = "External Security Group"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "bastion.kafka.${var.domain}"
  }
}

// Allow any internal network flow.
resource "aws_security_group_rule" "bastion_allow_all_internal" {
  security_group_id = "${aws_security_group.bastion.id}"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  self              = true
  type              = "ingress"
}

// Allow ALL OUTBOUND (ALL)
resource "aws_security_group_rule" "bastion_allow_all_out" {
  security_group_id = "${aws_security_group.bastion.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "egress"
}
