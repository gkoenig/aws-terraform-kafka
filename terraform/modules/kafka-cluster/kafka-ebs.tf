resource "aws_ebs_volume" "kafka" {
  count             = "${var.nr_kafka_nodes}"
  availability_zone = "${element(data.aws_availability_zones.all.names,count.index)}"
  size              = "${var.kafka-disksize}"
  type              = "${var.kafka-disktype}"
  encrypted         = true

  lifecycle {
      prevent_destroy = true
  }
  tags {
    Name = "kafka-${count.index}-${var.env}.${var.domain}"
  }
}


resource "aws_volume_attachment" "kafka" {
  count       = "${var.nr_kafka_nodes}"
  device_name = "/dev/xvdf"
  volume_id   = "${element(aws_ebs_volume.kafka.*.id, count.index)}"
  instance_id = "${element(aws_instance.kafka.*.id, count.index)}"
  # lifecycle {
  #   ignore_changes = [ "instance" ]
  # }
}
