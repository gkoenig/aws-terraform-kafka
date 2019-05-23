module "kafka" {
	source = "../../../modules/kafka-cluster/"
  
	stack_offset="${var.stack_offset}"

	# Environment Name
	env="${var.env}"
	domain="${var.domain}"


	# Define Kafka EC2 Instance and Disk Sizes
	kafka_ec2_type="${var.kafka_ec2_type}"
	ami="${var.ami}"
	kafka-disksize="${var.kafka-disksize}"
	kafka-disktype="${var.kafka-disktype}"

	vpc_state_bucket="${var.vpc_state_bucket}"
	vpc_state_key="${var.vpc_state_key}"
}
