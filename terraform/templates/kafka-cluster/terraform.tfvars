# Subnets and its CIDRS are incremented by the number of AZs 0,3,6,...
stack_offset=0

# Environment Name [dev-00, dev-01   or test-00, test-01]
env="{{build}}"
domain="{{env}}.{{aws.domain}}"


# Define Kafka EC2 Instance and Disk Sizes
kafka_ec2_type="t2.xlarge"
ami="ami-bfff49c2"
kafka-disksize=500
kafka-disktype="st1"

# VPC state location
vpc_state_bucket = "terraform.development.scigility"
vpc_state_key    = "development/vpc/terraform.tfstate"
