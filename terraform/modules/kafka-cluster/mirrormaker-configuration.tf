# dummy line to trigger null resource
data "template_file" "mirrormaker_consumer" {
  template = "${file("configs/mm-consumer.properties")}"

  vars {
    DOMAIN = "${var.domain}"
    ENV    =  "${var.env}"
    SRC_ENV = "prod"
  }
}

data "template_file" "mirrormaker_producer" {
  template = "${file("configs/mm-producer.properties")}"

  vars {
    DOMAIN = "${var.domain}"
    ENV    =  "${var.env}"
  }
}

resource "null_resource" "mirrormaker" {
  depends_on = ["aws_route53_record.zookeeper","null_resource.kafka"]

  #count    = "${var.nr_kafka_nodes}"
  count = "${var.mirrormaker ? var.nr_kafka_nodes : 0}"
  triggers {
    #server_id = "${element(aws_instance.kafka.*.id, count.index)}",
    mm_consumer = "${sha1(data.template_file.mirrormaker_consumer.rendered)}",
    mm_producer = "${sha1(data.template_file.mirrormaker_producer.rendered)}",
    mm-env-file = "${sha1(file("configs/mirrormaker.env"))}",
    mmm-log4j-file = "${sha1(file("configs/mm-log4j.properties"))}"
  }
  connection {
    user = "${var.ssh_user}"
    host = "${element(aws_instance.kafka.*.private_ip, count.index)}"
    private_key  = "${file("~/.ssh/kafka-${var.env}.pem")}"
    bastion_user = "${var.bastion_user}"
    bastion_host = "${data.terraform_remote_state.main.bastion_dns}"
    bastion_private_key = "${file("~/.ssh/kafka-${var.env}.pem")}"
    agent = false
  }

  provisioner "file" {
    content = "${data.template_file.mirrormaker_consumer.rendered}"
    destination = "/tmp/mm-consumer.properties"
  }
  provisioner "file" {
    content = "${data.template_file.mirrormaker_producer.rendered}"
    destination = "/tmp/mm-producer.properties"
  }
  provisioner "file" {
    source =  "configs/mirrormaker.env"
    destination = "/tmp/mirrormaker.env"
  }
  provisioner "file" {
    source =  "configs/mm-log4j.properties"
    destination = "/tmp/mm-log4j.properties"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/mm-consumer.properties /kafka/etc/",
      "sudo mv /tmp/mm-producer.properties /kafka/etc/",
      "sudo mv /tmp/mm-log4j.properties /kafka/etc/",
      "sudo mv /tmp/mirrormaker.env /kafka/etc/"
    ]
  }

  provisioner "file" {
    source = "configs/mirrormaker.service"
    destination = "/tmp/mirrormaker.service"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/mirrormaker.service /etc/systemd/system/",
      "sudo systemctl enable mirrormaker",
      "sudo systemctl restart mirrormaker"
    ]
  }

}
