output "kafka_private_dns" {
  value = ["${module.kafka.kafka_private_dns}"]
}

output "kafka_fqdn_dns" {
  value = ["${module.kafka.kafka_fqdn_dns}"]
}


output "zookeeper_private_dns" {
  value = ["${module.kafka.zookeeper_private_dns}"]
}

output "zookeeper_fqdn_dns" {
  value = ["${module.kafka.zookeeper_fqdn_dns}"]
}

output "bastion_dns" {
  value = ["${module.kafka.bastion_dns}"]
}

output "kafka_elb_dns" {
  value = "${module.kafka.kafka_elb_dns}"
}

output "zk_elb_dns" {
  value = "${module.kafka.zk_elb_dns}"
}

output "s3-sink-bucket" {
   value = "${module.kafka.s3-sink-bucket}"
}