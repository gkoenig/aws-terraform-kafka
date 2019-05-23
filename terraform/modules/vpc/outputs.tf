output "vpc_id" {
  value = "${aws_vpc.main.id}"
}

output "natgw_id" {
  value = "${aws_nat_gateway.natgw.id}"
}

output "subnet_public" {
  value = "${aws_subnet.public[0].id}"
}

output "bastion_dns" {
  value = "${aws_instance.bastion[0].public_dns}"
}

output "bastion_ip" {
  value = "${aws_instance.bastion[0].public_ip}"
}

output "bastion_ip_priv" {
  value = "${aws_instance.bastion[0].private_ip}"
}
