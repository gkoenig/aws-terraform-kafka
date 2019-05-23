data "template_file" "connect-distributed" {
  count = "${var.s3sink ? 1 : 0}"
  template = "${file("configs/connect-distributed.properties")}"

  vars {
    DOMAIN = "${var.domain}"
    ENV    =  "${var.env}"
  }
}

data "template_file" "connect-standalone" {
  count = "${var.s3sink ? 1 : 0}"
  template = "${file("configs/connect-standalone.properties")}"

  vars {
    DOMAIN = "${var.domain}"
    ENV    =  "${var.env}"
  }
}

data "template_file" "connect-standalone-s3-sink" {
  count = "${var.s3sink ? 1 : 0}"
  template = "${file("configs/kafka-connect-standalone-s3.properties")}"

  vars {
    DOMAIN = "${var.domain}"
    ENV    =  "${var.env}"
  }

}
data "template_file" "s3-sink-agency" {
  count = "${var.s3sink ? 1 : 0}"
  template = "${file("configs/s3-sink-agency.json")}"
  vars {
    DOMAIN = "${var.domain}"
    ENV    =  "${var.env}"
  }
}
data "template_file" "s3-sink-role" {
  count = "${var.s3sink ? 1 : 0}"
  template = "${file("configs/s3-sink-role.json")}"
  vars {
    DOMAIN = "${var.domain}"
    ENV    =  "${var.env}"
  }
}
data "template_file" "s3-sink-contract" {
  count = "${var.s3sink ? 1 : 0}"
  template = "${file("configs/s3-sink-contract.json")}"
  vars {
    DOMAIN = "${var.domain}"
    ENV    =  "${var.env}"
  }
}
data "template_file" "s3-sink-mm-test" {
  count = "${var.s3sink ? 1 : 0}"
  template = "${file("configs/s3-sink-mm-test.json")}"
  vars {
    DOMAIN = "${var.domain}"
    ENV    =  "${var.env}"
  }
}
data "template_file" "s3-sink-party" {
  count = "${var.s3sink ? 1 : 0}"
  template = "${file("configs/s3-sink-party.json")}"
  vars {
    DOMAIN = "${var.domain}"
    ENV    =  "${var.env}"
  }
}

resource "null_resource" "s3connectors" {
  depends_on = ["null_resource.kafkaconnect"]
  count = "${var.s3sink ? var.nr_kafka_nodes : 0}"

  triggers {
    agency-sink = "${sha1(data.template_file.s3-sink-agency.rendered)}",
    contract-sink = "${sha1(data.template_file.s3-sink-contract.rendered)}",
    mm-test-sink = "${sha1(data.template_file.s3-sink-mm-test.rendered)}",
    party-sink = "${sha1(data.template_file.s3-sink-party.rendered)}",
    role-sink = "${sha1(data.template_file.s3-sink-role.rendered)}"
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
    content =  "${data.template_file.s3-sink-agency.rendered}"
    destination = "/tmp/s3-sink-agency.json"
  }
  provisioner "file" {
    content =  "${data.template_file.s3-sink-contract.rendered}"
    destination = "/tmp/s3-sink-contract.json"
  }
  provisioner "file" {
    content =  "${data.template_file.s3-sink-mm-test.rendered}"
    destination = "/tmp/s3-sink-mm-test.json"
  }
  provisioner "file" {
    content =  "${data.template_file.s3-sink-party.rendered}"
    destination = "/tmp/s3-sink-party.json"
  }
  provisioner "file" {
    content =  "${data.template_file.s3-sink-role.rendered}"
    destination = "/tmp/s3-sink-role.json"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/s3-sink-agency.json /kafka/etc/",
      "sudo mv /tmp/s3-sink-contract.json /kafka/etc/",
      "sudo mv /tmp/s3-sink-mm-test.json /kafka/etc/",
      "sudo mv /tmp/s3-sink-party.json /kafka/etc/",
      "sudo mv /tmp/s3-sink-role.json /kafka/etc/"
    ]
  }
}

resource "null_resource" "kafkaconnect" {
  count = "${var.s3sink ? var.nr_kafka_nodes : 0}"
  depends_on = ["aws_s3_bucket.kafka_s3_bucket","null_resource.kafka"]

  count    = "${var.nr_kafka_nodes}"
  triggers {
    con-standalone = "${sha1(data.template_file.connect-distributed.rendered)}",
    con-distributed = "${sha1(data.template_file.connect-standalone.rendered)}",
    con-s3-sink = "${sha1(data.template_file.connect-standalone-s3-sink.rendered)}",
    con-log4j-file = "${sha1(file("configs/connect-distributed-log4j.properties"))}"
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
    content = "${data.template_file.connect-distributed.rendered}"
    destination = "/tmp/connect-distributed.properties"
  }
  provisioner "file" {
    content = "${data.template_file.connect-standalone.rendered}"
    destination = "/tmp/connect-standalone.properties"
  }
  provisioner "file" {
    content =  "${data.template_file.connect-standalone-s3-sink.rendered}"
    destination = "/tmp/connect-standalone-s3-sink.properties"
  }
  provisioner "file" {
    source =  "configs/connect-distributed-log4j.properties"
    destination = "/tmp/connect-distributed-log4j.properties"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/connect-distributed.properties /kafka/etc/",
      "sudo mv /tmp/connect-standalone.properties /kafka/etc/",
      "sudo mv /tmp/connect-standalone-s3-sink.properties /kafka/etc/",
      "sudo mv /tmp/connect-distributed-log4j.properties /kafka/etc/"
    ]
  }

  # provisioner "remote-exec" {
  #   inline = [
  #     "sudo systemctl restart connect-distributed"
  #   ]
  # }
}

resource "null_resource" "kafkaconnect-distributed-service" {
  count = "${var.s3sink ? var.nr_kafka_nodes : 0}"
  depends_on = ["null_resource.kafkaconnect"]

  count    = "${var.nr_kafka_nodes}"
  triggers {
    server_id = "${element(aws_instance.kafka.*.id, count.index)}",
    connect-distributed = "${sha1(file("configs/connect-distributed.service"))}"
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
    content = "${data.template_file.connect-distributed.rendered}"
    destination = "/tmp/connect-distributed.properties"
  }
  provisioner "file" {
    source = "configs/connect-distributed.service"
    destination = "/tmp/connect-distributed.service"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/connect-distributed.properties /kafka/etc/",
      "sudo mv /tmp/connect-distributed.service /etc/systemd/system/"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl daemon-reload",
      "sudo systemctl enable connect-distributed",
      "sudo systemctl restart connect-distributed"
    ]
  }
}
