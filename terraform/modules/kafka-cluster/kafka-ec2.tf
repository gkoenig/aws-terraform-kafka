data "template_file" "kafka" {
  count    = "${var.nr_kafka_nodes}"
  template = "${file("${path.module}/user_data/kafka.sh")}"

  vars = {
    BROKER_ID = "${count.index}"
    REGION = "${element(data.aws_availability_zones.all.names, count.index)}"
    DOMAIN = "${var.domain}"
    ENV    =  "${var.env}"
  }
}

data "template_cloudinit_config" "kafka" {
  count = "${var.nr_kafka_nodes}"

  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = "${element(data.template_file.kafka.*.rendered,count.index)}"
  }
}

resource "aws_instance" "kafka" {
  count         = "${var.nr_kafka_nodes}"
  ami           = "${var.ami}"
  instance_type = "${var.kafka_ec2_type}"
  key_name      = "${var.keyname}"
  subnet_id     = "${element(aws_subnet.main.*.id, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.kafka.id}"]
  associate_public_ip_address = true
  iam_instance_profile = ""

  user_data = "${element(data.template_cloudinit_config.kafka.*.rendered,count.index)}"


  root_block_device {
    volume_type           = "gp2"
    volume_size           = 10
    delete_on_termination = true
  }

  #connection {
  #  user = "centos"
  #  host = "${self.private_ip}"
  #  private_key  = "${file("~/.ssh/gk-paris.pem")}"
  #  bastion_host = "${data.aws_instance.bastion-host.public_dns}"
  #  bastion_private_key = "${file("~/.ssh/terraform-aws-kafka-bastion")}"
  #  agent = false
  #}

  provisioner "remote-exec" {
    when                  = "destroy"
    inline                = [
      "sudo systemctl stop kafka",
      "sudo umount /kafka"
    ]
  }

  # lifecycle {
  #   create_before_destroy = true
  # }

  timeouts {
    create = "30m"
    delete = "60m"
  }

  tags  = {
    Name = "kafka-${count.index}.${var.env}.${var.domain}"
    Customer = "Scigility"
    Project = "Scigility internal"
    Requestor = "GeKo"
    ExpirationDate = "2019-12-31"
  }
}


