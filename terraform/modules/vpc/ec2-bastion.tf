resource "aws_instance" "bastion" {
  count                       = 1
  ami                         = "${lookup(var.centos_ami, var.name)}"
  instance_type               = "t2.micro"
  key_name                    = "kafka"
  subnet_id                   = "${element(aws_subnet.public.*.id, count.index)}"
  vpc_security_group_ids      = ["${aws_security_group.bastion.id}"]
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 10
    delete_on_termination = true
  }

  tags {
    Name = "bastion-kafka.${var.name}.${var.domain}"
  }
}
