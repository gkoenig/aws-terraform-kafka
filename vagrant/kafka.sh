#!/bin/bash

# Add file limits configs - allow to open 100,000 file descriptors
echo "* hard nofile 100000
* soft nofile 100000" | sudo tee --append /etc/security/limits.conf

### EBS mount point
mkdir -p /data/kafka

useradd kafka
sudo chown -R kafka:kafka /data/kafka

curl -s -o kafka.tgz http://www-eu.apache.org/dist/kafka/0.11.0.0/kafka_2.12-0.11.0.0.tgz 
tar -xvzf kafka.tgz
sudo rm kafka.tgz
sudo mv kafka* /opt/kafka
sudo chown -R kafka. /opt/kafka 
cd /opt/kafka/

echo "
############################# Server Basics #############################

# The id of the broker. This must be set to a unique integer for each broker.
broker.id=1
# change your.host.name by your machine's IP or hostname
advertised.listeners=PLAINTEXT://kafka1:9092

# Switch to enable topic deletion or not, default value is false
delete.topic.enable=true

############################# Log Basics #############################

# A comma seperated list of directories under which to store log files
log.dirs=/data/kafka

# The default number of log partitions per topic. More partitions allow greater
# parallelism for consumption, but this will also result in more files across
# the brokers.
num.partitions=8
# we will have 3 brokers so the default replication factor should be 2 or 3
default.replication.factor=3
# number of ISR to have in order to minimize data loss
min.insync.replicas=2

############################# Log Retention Policy #############################

# The minimum age of a log file to be eligible for deletion due to age
# this will delete data after a week
log.retention.hours=168

# The maximum size of a log segment file. When this size is reached a new log segment will be created.
log.segment.bytes=1073741824

# The interval at which log segments are checked to see if they can be deleted according
# to the retention policies
log.retention.check.interval.ms=300000

############################# Zookeeper #############################

# Zookeeper connection string (see zookeeper docs for details).
# This is a comma separated host:port pairs, each corresponding to a zk
# server. e.g. "127.0.0.1:3000,127.0.0.1:3001,127.0.0.1:3002".
# You can also append an optional chroot string to the urls to specify the
# root directory for all kafka znodes.
#zookeeper.connect=zookeeper1:2181,zookeeper2:2181,zookeeper3:2181/kafka
zookeeper.connect=localhost:2181/kafka

# Timeout in ms for connecting to zookeeper
zookeeper.connection.timeout.ms=6000


############################## Other ##################################
# I recommend you set this to false in production.
# We'll keep it as true for the course
auto.create.topics.enable=true
" | sudo tee --append /opt/kafka/config/server.properties

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
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh

[Install]
WantedBy=multi-user.target
" | sudo tee --append  /etc/systemd/system/kafka.service


sudo systemctl daemon-reload
sudo systemctl enable kafka.service
sudo systemctl start kafka.service
sudo systemctl status kafka.service


# verify it's working
#figlet $(nc -v localhost 9092)
# look at the logs
# cat /home/ubuntu/kafka/logs/server.log
# make sure to fix the __consumer_offsets topic
#bin/kafka-topics.sh --zookeeper zookeeper1:2181/kafka --config min.insync.replicas=1 --topic __consumer_offsets --alter

