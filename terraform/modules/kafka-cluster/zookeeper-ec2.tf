data "template_file" "zookeeper" {
  count    = "${var.nr_zk_nodes}"
  template = "${file("${path.module}/user_data/zookeeper.sh")}"

  vars = {
    ZK_ID = "${count.index}"
    DOMAIN = "${var.domain}"
    ENV = "${var.env}"
  }
}

data "template_cloudinit_config" "zookeeper" {
  count = "${var.nr_zk_nodes}"

  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = "${element(data.template_file.zookeeper.*.rendered,count.index)}"
  }
}

resource "aws_instance" "zookeeper" {
  count                  = "${var.nr_zk_nodes}"
  ami                    = "${var.ami}"
  instance_type          = "t2.small"
  key_name               = "${var.keyname}"
  subnet_id              = "${element(aws_subnet.main.*.id, count.index)}"
  private_ip             = "${cidrhost(cidrsubnet(data.aws_vpc.main.cidr_block,8,length(data.aws_availability_zones.all.names) * var.stack_offset +count.index),251)}"
  vpc_security_group_ids = ["${aws_security_group.zookeeper.id}"]
  associate_public_ip_address = true

  user_data = "${element(data.template_cloudinit_config.zookeeper.*.rendered,count.index)}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
}

  tags ={
    Name = "zk-${count.index}.${var.env}.${var.domain}"
    Customer = "Scigility"
    Project = "Scigility internal"
    Requestor = "GeKo"
    ExpirationDate = "2019-12-31"
  }
}
