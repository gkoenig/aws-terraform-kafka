data "template_file" "kafka_props" {
  count    = "${var.nr_kafka_nodes}"
  template = "${file("configs/kafka.properties")}"

  vars = {
    BROKER_ID = "${count.index}"
    REGION = "${element(data.aws_availability_zones.all.names, count.index)}"
    DOMAIN = "${var.domain}"
    ENV    =  "${var.env}"
  }
}

resource "null_resource" "kafka" {
  depends_on = ["aws_volume_attachment.kafka","aws_route53_record.zookeeper","null_resource.zookeeper","null_resource.ssl"]

  count    = "${var.nr_kafka_nodes}"
  triggers ={
    #server_id = "${element(aws_instance.kafka.*.id, count.index)}",
    kafka_properties = "${sha1(element(data.template_file.kafka_props.*.rendered, count.index))}"
    prometheus_cfg = "${sha1(file("configs/kafka-prometheus.yml"))}"
    kafka_plain_jaas = "${sha1(file("configs/kafka-plain-jaas.conf"))}"
    ssl_client_properties = "${sha1(file("configs/ssl-client.properties"))}"
  }
  connection {
    user = "${var.ssh_user}"
    host = "${element(aws_instance.kafka.*.private_ip, count.index)}"
    private_key  = "${file("~/.ssh/gk-paris.pem")}"
    bastion_user = "${var.bastion_user}"
    bastion_host = "${data.aws_instance.bastion-host.public_dns}"
    bastion_private_key = "${file("~/.ssh/gk-paris.pem")}"
    agent = false
  }

  provisioner "remote-exec" {
    inline = [
      "test -d /tmp/terraform  ||  mkdir -p /tmp/terraform/etc"
    ]
  }

  provisioner "file" {
    source = "configs/ssl-client.properties"
    destination = "/tmp/terraform/ssl/ssl-client.properties"
  }

  provisioner "file" {
    content = "${element(data.template_file.kafka_props.*.rendered,count.index)}"
    destination = "/tmp/terraform/etc/kafka.properties"
  }

  provisioner "file" {
    source = "${path.module}/prometheus"
    destination = "/tmp/terraform"
  }

  provisioner "file" {
    source = "configs/kafka-prometheus.yml"
    destination = "/tmp/terraform/etc/kafka-prometheus.yml"
  }

  provisioner "file" {
    source = "configs/kafka-plain-jaas.conf"
    destination = "/tmp/terraform/etc/kafka-plain-jaas.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rsync -av -b /tmp/terraform/ /kafka/",
      "sudo chown -R kafka /kafka",
      "sudo rm -rf /tmp/terraform"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl daemon-reload",
      "sudo systemctl enable kafka",
      "sudo systemctl restart kafka"
    ]
  }
}

resource "null_resource" "kafka-service" {
  depends_on = ["null_resource.kafka"]

  count    = "${var.nr_kafka_nodes}"
  triggers ={
    server_id = "${element(aws_instance.kafka.*.id, count.index)}"
    kafka_service_cfg = "${sha1(file("configs/kafka.service"))}"
  }
  connection {
    user = "${var.ssh_user}"
    host = "${element(aws_instance.kafka.*.private_ip, count.index)}"
    private_key  = "${file("~/.ssh/gk-paris.pem")}"
    #bastion_user = "${var.bastion_user}"
    #bastion_host = "${data.aws_instance.bastion-host.public_dns}"
    #bastion_private_key = "${file("~/.ssh/gk-paris.pem")}"
    agent = false
  }

  provisioner "file" {
    source = "configs/kafka.service"
    destination = "/tmp/kafka.service"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/kafka.service /etc/systemd/system/"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl daemon-reload",
      "sudo systemctl enable kafka",
      "sudo systemctl restart kafka"
    ]
  }
}


