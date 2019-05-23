output "kafka_private_dns" {
  value = ["${aws_instance.kafka.*.private_dns}"]
}

output "kafka_elb_dns" {
  value = "${aws_route53_record.kafka_elb.fqdn}"
}

output "zk_elb_dns" {
  value = "${aws_route53_record.zk_elb.fqdn}"
}

output "kafka_fqdn_dns" {
  value = ["${aws_route53_record.kafka.*.fqdn}"]
}


output "zookeeper_private_dns" {
  value = ["${aws_instance.zookeeper.*.private_dns}"]
}

output "zookeeper_fqdn_dns" {
  value = ["${aws_route53_record.zookeeper.*.fqdn}"]
}

output "bastion_dns" {
  value = ["${data.terraform_remote_state.main.bastion_dns}"]
}

output "s3-sink-bucket" {
   value = "${join(" ",aws_s3_bucket.kafka_s3_bucket.*.bucket)}"
}
