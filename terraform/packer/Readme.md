# AWS EC2 Images creation (AMI)

To create AMI images we use [packer.io]().

Packer installs starts with a base CENTOS AMI, [https://wiki.centos.org/Cloud/AWS], and it is customized through provisioner scripts.

After the image is customized, packer creates an AMI and publishes on the IAM account on AWS to be used.

# Create AMI

## Pre-requisites

In order to run packer, one needs:

>* aws-cli access and configured
>* a VPC and a PUBLIC SUBNET for packer to launc an EC2 and create an AMI
>* ssh access to EC2 instances on above subnet

## Run Packer

### Configuration

Create a _variable file_ as *_integration-vars.json_* or *_production-vars.json_* :

```
{
"VPC":"vpc-0f370167",
"SUBNET":"subnet-75b58e0f",
"SOURCE_AMI":"ami-7cbc6e13"
}
```

### Validate the packer configuration

using packer

```
# for integration
packer validate  -var-file=integration-vars.json packer-centos-ami-integration.json

# for production
packer validate -var-file=production-vars.json packer-centos-ami-integration.json
```


using makefile

```
# for integration
make validate-integration

# for production
make validate-production
```

### Create AMI 
using packer

```
# for integration
packer build -only=amazon-ebs -var-file=integration-vars.json packer-centos-ami-integration.json 

# for production
packer build -only=amazon-ebs -var-file=production-vars.json packer-centos-ami-integration.json
```

using makefile:

```
# for integration
make ami-integration

# for production
make ami-production
```
