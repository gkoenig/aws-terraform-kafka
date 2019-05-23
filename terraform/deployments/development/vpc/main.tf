module "vpc" {
	source = "git@github.com:gkoenig/aws-terraform-kafka.git//terraform/modules/vpc/"
	vpc_cidr="${var.vpc_cidr}"
	domain="${var.domain}"
	name="${var.name}"
	centos="${var.centos}"
}
