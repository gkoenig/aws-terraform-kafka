ami-integration:
	packer build -only=amazon-ebs -var-file=integration-vars.json packer-centos-ami-integration.json
validate-integration:
	packer validate  -var-file=integration-vars.json packer-centos-ami-integration.json
ami-production:
	packer build -only=amazon-ebs -var-file=production-vars.json packer-centos-ami-integration.json
validate-production:
	packer validate -var-file=production-vars.json packer-centos-ami-integration.json
