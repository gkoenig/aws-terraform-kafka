data "template_file" "zookeeper_props" {
  count    = "${var.nr_zk_nodes}"
  template = "${file("configs/zookeeper.properties")}"

  vars = {
    DOMAIN = "${var.domain}"
    ENV = "${var.env}"
  }
}

data "template_file" "zookeeper_service" {
  count    = "${var.nr_zk_nodes}"
  template = "${file("configs/zookeeper.service")}"

  vars = {
    DOMAIN = "${var.domain}"
    ENV = "${var.env}"
    ZK_ID = "${count.index}"
  }
}

resource "null_resource" "zookeeper" {
  depends_on = ["aws_route53_record.zookeeper"]

  count    = "${var.nr_zk_nodes}"

  triggers = {
    #server_id = "${element(aws_instance.zookeeper.*.id, count.index)}"
    zk_properties = "${sha1(element(data.template_file.zookeeper_props.*.rendered, count.index))}"
    zk_service = "${sha1(element(data.template_file.zookeeper_service.*.rendered, count.index))}"
    zk_jaas = "${sha1(file("configs/zk-plain-jaas.conf"))}"
  }
  connection {
    user = "${var.ssh_user}"
    host = "${element(aws_instance.zookeeper.*.private_ip, count.index)}"
    private_key  = "${file("~/.ssh/gk-paris.pem")}"
    bastion_user = "${var.bastion_user}"
    bastion_host = "${data.aws_instance.bastion-host.public_dns}"
    bastion_private_key = "${file("~/.ssh/gk-paris.pem")}"
    agent = false
  }
  provisioner "file" {
    content = "${element(data.template_file.zookeeper_props.*.rendered,count.index)}"
    destination = "/tmp/zookeeper.properties"
  }

  provisioner "file" {
    content = "${element(data.template_file.zookeeper_service.*.rendered,count.index)}"
    destination = "/tmp/zookeeper.service"
  }

  provisioner "file" {
    source = "configs/zookeeper-prometheus.yml"
    destination = "/tmp/zookeeper-prometheus.yml"
  }
  provisioner "file" {
    source = "configs/zk-plain-jaas.conf"
    destination = "/tmp/zk-plain-jaas.conf"
  }
  provisioner "file" {
    source = "${path.module}/prometheus"
    destination = "/tmp"
  }

  # set instance id
  provisioner "remote-exec" {
    inline = [
      "echo ${count.index} | sudo tee /zookeeper/data/myid"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/zookeeper.properties /zookeeper/etc/",
      "sudo mv /tmp/zookeeper.service /etc/systemd/system/",
      "sudo mv /tmp/zookeeper-prometheus.yml /zookeeper/etc/",
      "sudo mv /tmp/zk-plain-jaas.conf /zookeeper/etc/zk-plain-jaas.conf",
      "sudo mkdir /zookeeper/prometheus",
      "sudo chown -R zookeeper:zookeeper /zookeeper/prometheus",
      "sudo mv /tmp/prometheus/* /zookeeper/prometheus/"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl daemon-reload",
      "sudo systemctl enable zookeeper",
      "sudo systemctl restart zookeeper"
    ]
  }
}
