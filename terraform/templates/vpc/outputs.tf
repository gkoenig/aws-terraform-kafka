output "vpc_id" {
   value = "${module.vpc.vpc_id}"
}

output "natgw_id" {
   value = "${module.vpc.natgw_id}"
}

output "subnet_public" {
   value = "${module.vpc.subnet_public}"
}

output "bastion_dns" {
   value = "${module.vpc.bastion_dns}"
}

output "bastion_ip" {
   value = "${module.vpc.bastion_ip}"
}

