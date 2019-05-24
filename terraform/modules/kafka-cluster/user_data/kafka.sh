#!/bin/bash

# Add user kafka if it not exists
id -u kafka >/dev/null 2>&1 || sudo useradd kafka

# EBS volume
lsblk

# Wait for volume to be available
while [ ! -e /dev/xvdf ]; do
     sleep 10
done

# # Format is no filesystem available
if [ "$(file -b -s /dev/xvdf)" == "data" ]; then
    # Create Filesystem and setup from scratch
    mkfs.xfs /dev/xvdf
fi

# Create /kafka if does not exist
test -d /kafka || mkdir /kafka
chown -R kafka:kafka /kafka /var/log/kafka

# mount volume
mount /dev/xvdf /kafka

if ! grep /dev/xvdf /etc/fstab; then
     echo >> /etc/fstab
     echo "/dev/xvdf    /kafka   xfs  defaults  0  0" >> /etc/fstab
fi

# # check it's working
df -h /kafka

# # create kafka directories
test -d /kafka/data || mkdir -p  /kafka/data
test -d /kafka/etc  || mkdir -p  /kafka/etc
#test -d /kafka/etc/ssl  || mkdir -p  /kafka/etc/ssl # No need, as the directory is included on the zipfile
test -d /kafka/log  || mkdir -p  /kafka/log
# # add permissions to kafka directory
chown -R kafka:kafka /kafka

# COPY SSL certificates from S3
yum install -y python-pip
pip install awscli

export DOM=${DOMAIN}


sudo reboot
