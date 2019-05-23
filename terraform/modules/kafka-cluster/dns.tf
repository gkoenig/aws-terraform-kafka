resource "aws_route53_zone" "kafka" {
   name   = "${var.env}.${var.domain}"
   vpc_id = "${data.terraform_remote_state.main.vpc_id}"
}


resource "aws_route53_record" "zookeeper" {
   count = "${var.nr_zk_nodes}"

   zone_id = "${aws_route53_zone.kafka.zone_id}"
   name    = "zk-${count.index}"
   type    = "A"
   ttl     = "300"
   records = ["${element(aws_instance.zookeeper.*.private_ip, count.index)}"]
 }

 resource "aws_route53_record" "kafka" {
   count = "${var.nr_kafka_nodes}"

   zone_id = "${aws_route53_zone.kafka.zone_id}"
   name    = "kafka-${count.index}"
   type    = "A"
   ttl     = "300"
   records = ["${element(aws_instance.kafka.*.private_ip, count.index)}"]
 }



resource "aws_route53_zone_association" "k8s" {
  zone_id = "${aws_route53_zone.kafka.zone_id}"
  vpc_id  = "${data.terraform_remote_state.main.vpc_peer_id}"
}


#############################################################
# Round Robin for zookeeper.<env.domain> for all zookeeper nodes
#############################################################
resource "aws_route53_record" "zk_elb" {
  zone_id = "${aws_route53_zone.kafka.zone_id}"
  name = "zookeeper"
  type = "CNAME"
  ttl = "60"
  records = ["${aws_elb.zookeeper.dns_name}"]
}


#############################################################
# Round Robin for kafak.<env.domain> for all kafka nodes
#############################################################
resource "aws_route53_record" "kafka_elb" {
  zone_id = "${aws_route53_zone.kafka.zone_id}"
  name = "kafka"
  type = "CNAME"
  ttl = "60"
  records = ["${aws_elb.kafka.dns_name}"]
}
