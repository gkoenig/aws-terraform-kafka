#! /bin/bash

# Packages
sudo yum update -y
sudo yum install -y epel-release 
sudo yum install -y xfsprogs
sudo yum install -y zip wget netcat net-tools ca-certificates nmap-ncat figlet telnet lsof

# Java Open JDK 8
sudo yum install -y java-1.8.0-openjdk
sudo java -version

# Add file limits configs - allow to open 100,000 file descriptors
echo "* hard nofile 100000
* soft nofile 100000" | sudo tee --append /etc/security/limits.conf

echo "
[Confluent.dist]
name=Confluent repository (dist)
baseurl=http://packages.confluent.io/rpm/3.3/7
gpgcheck=1
gpgkey=http://packages.confluent.io/rpm/3.3/archive.key
enabled=1

[Confluent]
name=Confluent repository
baseurl=http://packages.confluent.io/rpm/3.3
gpgcheck=1
gpgkey=http://packages.confluent.io/rpm/3.3/archive.key
enabled=1" | sudo tee /etc/yum.repos.d/confluent.repo

sudo yum clean all
sudo yum install -y confluent-platform-oss-2.11

# Add user kafka and zookeeper
sudo useradd kafka
sudo useradd zookeeper

############################################
# Install Zookeeper boot scripts
############################################
echo "[Unit]
Description=Apache Zookeeper server 
Documentation=http://zookeeper.apache.org
Requires=network.target remote-fs.target 
After=network.target remote-fs.target

[Service]
Type=simple
User=zookeeper
SyslogIdentifier=zookeeper
Restart=always
RestartSec=0s
Group=zookeeper
ExecStart=/usr/bin/zookeeper-server-start /etc/kafka/zookeeper.properties
ExecStop=/usr/bin/zookeeper-server-stop
ExecReload=/usr/bin/zookeeper-server-stop && /usr/bin/zookeeper-server-start /etc/kafka/zookeeper.properties
WorkingDirectory=/zookeeper

[Install]
WantedBy=multi-user.target
" | sudo tee /etc/systemd/system/zookeeper.service

############################################
# Install Kafka boot scripts
############################################
echo "
[Unit]
Description=Apache Kafka server (broker)
Documentation=http://kafka.apache.org/documentation.html
Requires=network.target remote-fs.target 
After=network.target remote-fs.target zookeeper.service

[Service]
Type=simple
User=kafka
Group=kafka
Environment=JAVA_HOME=/etc/alternatives/jre
ExecStart=/usr/bin/kafka-server-start /etc/kafka/server.properties
ExecStop=/usr/bin/kafka-server-stop

[Install]
WantedBy=multi-user.target
" | sudo tee /etc/systemd/system/kafka.service


sudo rm -rf /var/cache/yum