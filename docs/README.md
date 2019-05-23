Managing Kafka Cluster in AWS via Terraform

<!-- TOC START min:1 max:4 link:true update:true -->
- [Base architecture / design principles](#base-architecture--design-principles)
- [How to deploy a new environment](#how-to-deploy-a-new-environment)
  - [Create VPC](#create-vpc)
- [How to deploy a new cluster](#how-to-deploy-a-new-cluster)
- [How to apply a configuration change](#how-to-apply-a-configuration-change)
- [How to scale no of Kafka Brokers](#how-to-scale-no-of-kafka-brokers)
  - [config change](#config-change)
    - [SCALE UP](#scale-up)
    - [SCALE DOWN](#scale-down)
  - [check no of Kafka Brokers via Zookeeper](#check-no-of-kafka-brokers-via-zookeeper)
  - [create a test topic to ensure the new broker is _active_](#create-a-test-topic-to-ensure-the-new-broker-is-active)
- [How to replace a failed EC2 instance](#how-to-replace-a-failed-ec2-instance)
- [Replication of Topics from Prod](#replication-of-topics-from-prod)
  - [Configuration of MirrorMaker](#configuration-of-mirrormaker)
  - [managing MirrorMaker process](#managing-mirrormaker-process)
  - [Check if replication is running/catching up](#check-if-replication-is-runningcatching-up)
    - [start producing data to topic _mm-test_](#start-producing-data-to-topic-mm-test)
    - [check target topic in repl cluster](#check-target-topic-in-repl-cluster)
    - [check MirrorMaker consumer(s) lag](#check-mirrormaker-consumers-lag)
- [Security](#security)
  - [SASL_PLAINTEXT for Kafka Brokers](#saslplaintext-for-kafka-brokers)
  - [SASL_SSL connection to Kafka Brokers](#saslssl-connection-to-kafka-brokers)
  - [SASL between Zookeeper servers](#sasl-between-zookeeper-servers)
- [Backup to S3](#backup-to-s3)
  - [Connect-Distributed Framework](#connect-distributed-framework)
  - [Connect S3-sink's](#connect-s3-sinks)
    - [sink configurations](#sink-configurations)
    - [s3-sink enabling](#s3-sink-enabling)
    - [list connectors](#list-connectors)
    - [delete s3-sink connector](#delete-s3-sink-connector)

<!-- TOC END -->


All the scripts to deploy/config a new environment consisting of Kafka and Zookeeper can be found in folder [/terraform](../terraform)

# Base architecture / design principles
see [architecture doc](../terraform/Readme.md)

# How to deploy a new environment

## Create VPC

* Create a new S3 bucket to store state
* Create a new SSH Keypair
* Create VPC
* Create AMI with root disk encrypted
* Adjust CLUSTER inputs.tf to have the rigt AMI

# How to deploy a new cluster

* go to ``` <git-root>/aws-terraform-kafka/terraform/deployments/[integration|production]```
* create a directory for your new environment, e.g. _prod_
* getting the skeleton by ```terraform init -from-module=../../../templates/kafka-cluster```
  * edit _provider.tf_ and adjust
    * s3 bucket name
    * ...and its key
  * edit _terraform.tfvars_ and
    * increase property ```stack_offset``` by 1
    * set the name of the environment in property ```env=```
    * set the domain, incl. the _aws-01XY_ number
    * check if the AMI, instance type and EBS size fits
    * specify the bucket and key for the VPC state, default value should match   
    **!!!** this is not the same S3 bucket as defined beforehand in file _provider.tf_ **!!!**
  * ```terraform init```  
  enter _no_ at question "Do you want to copy the state from "s3"?"
  * ```terraform plan -out kafka-<environment>.plan```
  * ```terraform apply "kafka-<environment>.plan"```

# How to apply a configuration change
tbd.

# How to scale no of Kafka Brokers
## config change
To scale the no of Kafka Brokers in your cluster, the terraform variable **nr_kafka_nodes** needs to be overwritten (default value is **3**). To do so, edit file _main.tf_ and add the variable with the desired number of Kafka Brokers (==EC2 instances), e.g.
```
nr_kafka_nodes=4
```
To apply this change, execute
```
terraform plan
# verify that the output matches what needs to be done
terraform apply
```
### SCALE UP
The test run in _repl_ environment for **scaling up from 3 to 4 Brokers**, reported:
```
Apply complete! Resources: 5 added, 0 changed, 1 destroyed.

Outputs:

bastion_dns = [
    ec2-18-194-183-200.eu-central-1.compute.amazonaws.com
]
kafka_fqdn_dns = [
    kafka-0.some.domain,
    kafka-1.some.domain,
    kafka-2.some.domain,
    kafka-3.some.domain
]
kafka_private_dns = [
    ip-172-16-3-201.eu-central-1.compute.internal,
    ip-172-16-4-73.eu-central-1.compute.internal,
    ip-172-16-5-68.eu-central-1.compute.internal,
    ip-172-16-3-98.eu-central-1.compute.internal
]
zookeeper_fqdn_dns = [
    zk-0.some.domain,
    zk-1.some.domain,
    zk-2.some.domain
]
zookeeper_private_dns = [
    ip-172-16-3-251.eu-central-1.compute.internal,
    ip-172-16-4-251.eu-central-1.compute.internal,
    ip-172-16-5-251.eu-central-1.compute.internal
]
```
### SCALE DOWN
The test run ```terraform plan``` in _repl_ environment for **scaling down from 4 to 3 Brokers** reported:
```
Terraform will perform the following actions:

  - module.kafka.aws_ebs_volume.kafka[3]

  - module.kafka.aws_instance.kafka[3]

  - module.kafka.aws_route53_record.kafka[3]

  ~ module.kafka.aws_route53_record.kafka_roundrobin
      records.#:          "4" => "3"
      records.1666470670: "172.16.3.201" => "172.16.3.201"
      records.2960848627: "172.16.3.98" => ""
      records.311014880:  "172.16.5.68" => "172.16.5.68"
      records.620509772:  "172.16.4.73" => "172.16.4.73"

  - module.kafka.aws_volume_attachment.kafka[3]

  - module.kafka.null_resource.kafka[3]

  - module.kafka.null_resource.mirrormaker[3]

  - module.kafka.null_resource.rest_proxy[3]


Plan: 0 to add, 1 to change, 7 to destroy.
```
Looks exactly what was expected, apply the change by running ```terraform apply```


## check no of Kafka Brokers via Zookeeper
to list the broker ids which are registered in Zookeeper, just execute the command below. The output omits all useless overhead and formats the ids as a space separated list
```
zookeeper-shell zk-0.some.domain:2181/kafka ls /brokers/ids | egrep "\[|\]" | awk '{print substr($0,2,length($0)-2)}' | sed 's/,//g'
```

## create a test topic to ensure the new broker is _active_
* for this test the recently added Kafka Broker has id **3** , means cluster has been scaled up from (default) 3 to 4 Kafka Brokers.
```
kafka-topics --zookeeper zk-0.some.domain:2181/kafka --create --partitions 8 --replication-factor 2 --topic scaling-test
```
* let's _describe_ the topic to verify which brokers are actively managing partitions
```
kafka-topics --zookeeper zk-0.some.domain:2181,zk-1.some.domain:2181/kafka --describe --topic scaling-test
Topic:scaling-test	PartitionCount:8	ReplicationFactor:2	Configs:
	Topic: scaling-test	Partition: 0	Leader: 2	Replicas: 2,3	Isr: 2,3
	Topic: scaling-test	Partition: 1	Leader: 3	Replicas: 3,1	Isr: 3,1
	Topic: scaling-test	Partition: 2	Leader: 0	Replicas: 0,1	Isr: 0,1
	Topic: scaling-test	Partition: 3	Leader: 1	Replicas: 1,2	Isr: 1,2
	Topic: scaling-test	Partition: 4	Leader: 2	Replicas: 2,3	Isr: 2,3
	Topic: scaling-test	Partition: 5	Leader: 3	Replicas: 3,1	Isr: 3,1
	Topic: scaling-test	Partition: 6	Leader: 0	Replicas: 0,1	Isr: 0,1
	Topic: scaling-test	Partition: 7	Leader: 1	Replicas: 1,2	Isr: 1,2
```
==> Broker **3** is in operational mode  
* delete the topic
```
kafka-topics --zookeeper zk-0.some.domain:2181/kafka --delete --topic scaling-test
```

# How to replace a failed EC2 instance
see corresponding document describing [failurescenarios](./failurescenarios.md)

# Replication of Topics from Prod
The tool MirrorMaker will be used to replicate topics from Prod to another cluster. It just replicates the "data", no metadata like e.g. topic configuration.  
MirrorMaker itself runs in the target environment and acts as Consumer from Prod and a Producer to destination, hence network needs to be prepared for that if applicable.

An instance of MirrorMaker is setup/started on **any** Kafka-Broker node in the **repl** environment.


## Configuration of MirrorMaker
MM requires (at least) a config for the consumer part as well as a config for the producer, and a list of topics to replicate.  
The corresponding files can be found in _<git-root>/terraform/modules/kafka-cluster/configs_  , files _mm-consumer.properties_, _mm-producer.properties_ and _mirrormaker.env_. To adjust the log4j settings for MirrorMaker, use _mm-log4j.properties_.  
As a prerequisite for starting Mirrormaker you have to ensure that all topics, you are going to replicate, exist on the replication cluster, because **no autocreation** of topics will happen.   
To specify the topics to be replicated, set **MIRRORMAKER_WHITELIST** in file _mirrormaker.env_ appropriately. Value is either a single topic name, or a regex expression.

All topics in the repl cluster has been created with a **replication factor of 2**, to not overkill the number of replicas per message.  

For testing purposes there is the topic _mm-test_, with a **retention time of 0.5hrs**, so that the data gets deleted asap.

## managing MirrorMaker process
MM process is managed by systemd, hence by the following statements (executed on one of the repl Kafka-Broker nodes):
```
sudo systemctl status [-l] mirrormaker
sudo systemctl stop mirrormaker
sudo systemctl start mirrormaker
```
Keep in mind that an instance of MirrorMaker is running (usually) on any Kafka-Broker node in the repl environment.  

## Check if replication is running/catching up
Start the following tools/processes in **separate** terminals.
### start producing data to topic _mm-test_
Since the content doesn't matter we can use the _perftest_ to produce a bunch of test messages. The below command throttles the throughput and creates very small messages to avoid wasting disk space.
```
kafka-producer-perf-test \
--topic mm-test \
--num-records 100000 \
--record-size 10 \
--throughput 100 \
--producer-props bootstrap.servers=kafka-0.prod.some.domain:9092,kafka-1.prod.some.domain:9092,kafka-2.prod.some.domain:9092
```
### check target topic in repl cluster
To finally check if the messages arrive on the repl cluster, just start a console-consumer to read from topic _mm-test_
```
kafka-console-consumer \
--bootstrap-server kafka-0.some.domain:9092 \
--topic mm-test
```
### check MirrorMaker consumer(s) lag
The consumers within MirrorMaker are started within the same _consumer group_, hence observing this group is recommended:
```
kafka-consumer-groups \
--bootstrap-server kafka-0.prod.some.domain:9092 \
--new-consumer --describe \
--group mirrormaker_group | grep mm-test | awk '{print "topic:"$1, "\tpartition:"$2,$3,$4 "\tlag=" $5}'
```

# Security
## SASL_PLAINTEXT for Kafka Brokers
SASL_PLAINTEXT is available on port *9093*, and the client credentials needs to be grabbed from 1Password.

Test via console-consumer to read message incl SASL_PLAINTEXT auth from topic _configtest_ (in _test_ environment):

  ```
  export KAFKA_OPTS="-Djava.security.auth.login.config=/kafka/etc/kafka-plain-jaas.conf" ; kafka-console-consumer --bootstrap-server kafka-0.test.integration.some.domain:9093 --topic configtest --consumer-property security.protocol=SASL_PLAINTEXT --consumer-property sasl.mechanism=PLAIN --from-beginning
  ```

## SASL_SSL connection to Kafka Brokers
SASL_SSL is available on port *9095*. It uses the same authentication mechanism as SASL_PLAINTEXT, but on an encrypted channel. Therefore additional properties are required for the clients to connect, see below.

* producing dummy data into topic _mm-test_, connecting via SASL\_SSL  
file /kafka/etc/producer-saslssl.properties :
```
security.protocol=SASL_SSL
sasl.mechanism=PLAIN
ssl.truststore.location=/kafka/ssl/kafka.client.truststore.jks
ssl.truststore.password=<<grab-from-1password>>
bootstrap.servers=kafka-0.some.domain:9095,kafka-1.some.domain:9095,kafka-2.some.domain:9095
```
start ingesting dummy data
```
export KAFKA_OPTS="-Djava.security.auth.login.config=/kafka/etc/kafka-plain-jaas.conf" ; kafka-producer-perf-test \
--topic mm-test \
--num-records 100000 \
--record-size 10 \
--throughput 1000 \
--producer.config /kafka/etc/producer-saslssl.properties
```
* consuming via SASL\_SSL  
file /kafka/etc/kafka_sasl_client.properties :
```
security.protocol=SASL_SSL
sasl.mechanism=PLAIN
ssl.truststore.location=/kafka/ssl/kafka.client.truststore.jks
ssl.truststore.password=<<grab-from-1password>>
```
start consumer:
```
export KAFKA_OPTS="-Djava.security.auth.login.config=/kafka/etc/kafka-plain-jaas.conf" ; kafka-console-consumer --bootstrap-server kafka-0.some.domain:9095 --topic mm-test --consumer.config /kafka/etc/kafka_sasl_client.properties
```


## SASL between Zookeeper servers
To secure the communication between Zookeeper servers during LeaderElection, this communication can also be secured by e.g. using _SASL Digest-MD5_. The following properties have been added to zookeeper.properties to enable this behaviour:
* quorum.auth.enableSasl=true
* quorum.auth.learnerRequireSasl=true
* quorum.auth.serverRequireSasl=true
* quorum.cnxn.threads.size=50
In addition to that, the jaas file which is being used at zookeeper startup needs to be extended by the sections for the Leader and Server:
```
QuorumServer {
org.apache.zookeeper.server.auth.DigestLoginModule required
user_zkquorum="<<pw from 1Password>>";
};
QuorumLearner {
org.apache.zookeeper.server.auth.DigestLoginModule required
username="zkquorum"
password="<<pw from 1Password>>";
};
```

# Backup to S3
For backup purposes Kafka-Connect is used to write topics to S3. Connect runs in distributed mode on all Kafka nodes in Prod environment, and is started automatically. Uploading the final connector config for the *s3-sink-<topic>*s is a manual task.

## Connect-Distributed Framework
If there is the need to restart the Connect-distributed framework itself, there are appropriate systemd configs/commands available
```
sudo systemctl status connect-distributed
sudo systemctl stop connect-distributed
sudo systemctl start connect-distributed
sudo systemctl restart connect-distributed
```
...the config itself is in _/kafka/etc/connect-distributed.properties_

## Connect S3-sink's
### sink configurations
The properties for each s3-sink connector are specified in a json file under _/kafka/etc/_, one file per topic "category", prefixed by _s3-sink_ (e.g. _s3-sink-agency.json_ / _s3-sink-contract.json_ / ...) .  
### s3-sink enabling
to upload the s3-sink configuration to the connect framework, the REST-API of the connect framework needs to be used as shown below. The required config in .json format is deployed by terraform:
```
curl  -i -X POST   -H "Accept:application/json"   -H "Content-Type:application/json"   --data @/kafka/etc/s3-sink-agency.json "http://kafka-0.prod.some.domain:8083/connectors"
```
### list connectors
```
curl -X GET http://kafka-0.prod.some.domain:8083/connectors
```
A sample response looks like:
```
[centos@ip-172-16-2-156 etc]$ curl -X GET http://kafka-2.prod.some.domain:8083/connectors
["s3-sink-role","s3-sink-party","s3-sink-agency","s3-sink-mm-test","s3-sink-contract"]
```
### delete s3-sink connector
```
curl -X DELETE http://<<kafkanode>>:8083/connectors/<<connector-name>>
```
