output "vpc_id" {
  value = "${aws_vpc.main.id}"
}

output "vpc_peer_id" {
  value = "${var.vpc_peer}"
}

output "natgw_id" {
  value = "${aws_nat_gateway.natgw.id}"
}

output "subnet_public" {
  value = "${aws_subnet.public.id}"
}

output "bastion_dns" {
  value = "${aws_instance.bastion.public_dns}"
}

output "bastion_ip" {
  value = "${aws_instance.bastion.public_ip}"
}

output "bastion_ip_priv" {
  value = "${aws_instance.bastion.private_ip}"
}

output "peering_connection_id" {
  value = "${aws_vpc_peering_connection.pc.id}"
}

