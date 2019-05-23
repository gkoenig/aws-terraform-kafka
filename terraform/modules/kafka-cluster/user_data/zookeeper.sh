#!/bin/bash

# Add  zookeeper USER
id -u zookeeper >/dev/null 2>&1 || sudo useradd zookeeper

# Disable RAM Swap - can set to 0 on certain Linux distro
sudo sysctl vm.swappiness=1
echo 'vm.swappiness=1' | sudo tee --append /etc/sysctl.conf
 
# create zookeeper directory
mkdir -p /zookeeper/data /zookeeper/log /zookeeper/etc 

# add permissions to zookeeper directory
chown -R zookeeper:zookeeper /zookeeper /var/log/kafka


