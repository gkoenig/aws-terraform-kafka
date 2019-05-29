resource "aws_instance" "bastion" {
  count                       = 1
  ami                         = "ami-bfff49c2"
  instance_type               = "t2.micro"
  key_name                    = "${aws_key_pair.bastion_key.key_name}"
  subnet_id                   = "${element(aws_subnet.public.*.id, count.index)}"
  vpc_security_group_ids      = ["${aws_security_group.bastion.id}"]
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 10
    delete_on_termination = true
  }

  tags = {
    Name = "bastion-kafka.${var.name}.${var.domain}"
  }
}

#
# ssh-keygen -t rsa -b 4096 -C "koenig.bodensee@googlemail.com" -f $HOME/.ssh/terraform-aws-kafka-bastion
#
resource "aws_key_pair" "bastion_key" {
  key_name   = "terraform-aws-kafka-bastion"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCejZOMqyyGKJE2z4dB9iJxVoSxCbQfzuq3TzaCf3V/v13gZw0eptgt2WoEIZOXDu2fP9Gmiv4EeSyFnUyAEc2vx8idh7w+nm214k9GjgLwsHBDqwG02acvpxk2hryje+UghdMgZwe+bTBo4FAJJH0cgpg3RdXtxwBH/zK2TcSS9WeC+SFEReJFlWCgKqTfsQLMo7dT5al0xXfsckfy1fQYWCzRtHIdrxVBYLQ28jRjNJ6uKv/xhOVl6NeedNDZmjR+hRFsCKJa9/UsduLNZSeJh3oCAdmULZc0lZR+ust4tWqkOLDKJ0e+pvXYvugLfUowTIydcOt1ruQKNAJyr6OGOCua871BpF5BeBZqRFKkydK0ijUcINFhgt52Sr8re/p9Pb3CghdbcHZFLCz2o22mWLBQvaqV3Ys45qVggRznHCJs7Ws4DpORG+i0iZFRPdm5wEAZsw72YQyeOcTxWlbA1ik0iFLfZ2FN+NW04X+2hmbfRat07nhefDp+grQkfLdqZQsadSB3MhWcbQHq9WZ6LHtgDv7ZRB/xqoY3/7NDoyRsQ+OFzExcFotfQUXJ/V605lxACemZHP9eInc5k0I+tfubfBkEgRNePx7AH8PM9m+7fg3mCaRZsPV+vK4HHUosj6fquwRZLefpTaP9B4jN0u3Ry54oCH7Kx/tdVRDeew== koenig.bodensee@googlemail.com"
}
