**TOC**
<!-- TOC START min:1 max:4 link:true update:true -->
  - [Intro](#intro)
  - [Failed Kafka node](#failed-kafka-node)
    - [Verification setup](#verification-setup)
    - [perform failure test](#perform-failure-test)
  - [Failed Zookeeper node](#failed-zookeeper-node)
    - [Verification setup](#verification-setup-1)
    - [perform failure test](#perform-failure-test-1)
  - [Loss of an EBS volume](#loss-of-an-ebs-volume)
    - [start producing messages and observing topic](#start-producing-messages-and-observing-topic)
    - [detach EBS volume](#detach-ebs-volume)
    - [check Kafka Broker](#check-kafka-broker)
    - [check producer / consumer / partitions](#check-producer--consumer--partitions)
    - [terminate Kafka instance](#terminate-kafka-instance)
    - [recreate EBS and EC2](#recreate-ebs-and-ec2)
    - [check after recreation of EBS and EC2](#check-after-recreation-of-ebs-and-ec2)

<!-- TOC END -->

Below you'll find several scenarios to demonstrate how to recover from failed nodes, to scale out, ...

## Intro
To monitor the basic availability of Zookeeper/Kafka during the scenarios, there is a test topic **mm-test** with a replication factor of **2** and **3** partitions.  

## Failed Kafka node
### Verification setup
There will be a producer running, writing continously dummy messages to the topic in **PROD**. A console-consumer will read from the topic in **REPL**, thereby also the MirrorMaker functionality is being checked.
* producing messages
```
kafka-producer-perf-test --topic mm-test \
--num-records 100000 --record-size 10 --throughput 100 \
 --producer-props bootstrap.servers=kafka-0.prod.some.domain:9092,kafka-1.prod.some.domain:9092,kafka-2.prod.some.domain:9092
```
The duration of this perf-test is roughly 16mins    

*  consuming messages
```
kafka-console-consumer \
--bootstrap-server kafka-0.some.domain:9092 \
--topic mm-test
```
* checking the state of the topic, continously
```
watch -n2 "kafka-topics --zookeeper zk-0.some.domain:2181/kafka --describe --topic mm-test"
```

Start each of the above commands in one terminal, followed by simulating your desired scenario.

### perform failure test
* Initial state
  * 3 Kafka nodes are up and running
  * topic is distributed and has 2 ISRs for each partition
![](./images/initial-kafka-nodes.png)  
![](./images/initial-topic-state.png)

* Terminate a Kafka node  
![](./images/kafka-node-terminated.png)

* Topic state shows missing ISRs, and leadership changed  
![](./images/topic-state-during-missing-kafka-node.png)

* launch a new Kafka Broker node
```
cd <git-root>/aws-terraform-kafka/terraform/deployments/production/repl
terraform plan # shows you what will be created/changed
terraform apply # actually starts recreation
```  
![](./images/terraform-apply-start.png)

  ...waiting some minutes...   
  ![](./images/terraform-apply-end.png)  
  ![](./images/topic-state-after-kafka-node-is-back.png)   
  ![](./images/kafka-node-recreated.png)   

## Failed Zookeeper node
### Verification setup
To verify that zk functionality is still provided, _describing_ a topic and monitoring the _mode_ of each zk service is done as described below.

Describe topic, specify two zk nodes in the connect string, because one of them will be terminated later on:  
```
watch -n3 "kafka-topics --zookeeper zk-0.some.domain:2181,zk-1.some.domain:2181/kafka --describe --topic mm-test"
```

Check the mode (_leader_ or _follower_) of each of zk instances
```
watch -n2 'for i in 0 1 2; do echo "zk-$i:"; echo -e "srvr" | nc -v zk-$i.some.domain 2181 2>/dev/null | grep Mode ; echo ""; done'
```

### perform failure test
* start the verification setup described above  
![](./images/zk-failure-initial-state.png)

* terminate **the leader** (zk-1.repl.prod....) from within AWS console => this simulates the _worst case_ scenario for zookeeper  
![](./images/zk-failure-failure-state.png)

* let terraform report what is missing now and needs to be rebuilt, and actually trigger the deployment    
```
cd <git-root>/aws-terraform-kafka/terraform/deployments/production/repl
terraform plan
terraform apply
```  
  During _terraform apply_ you will notice a short period where zookeeper is not responding, due to the leader election happening on joining the rebuilt zk node.

* all zookeepers are back in quorum  
![](./images/zk-failure-final-state.png)

## Loss of an EBS volume
From a high-level point of view, the steps for this scenario are:
* start a producer+consumer on topic _mm-test_, and check its partition assignment
* detach an EBS volume from one of the Kafka instances and delete the EBS volume
* check how the Kafka process on that instance behavious
* check that producing and consuming still works and how the partitions got reassigned (or, depending on the replication factor, check for underreplicated partitions)
* delete the Kafka instance
* run terraform to recreate the volume and Kafka instance
* after the broker joined the cluster, check the assignment of partitions again

This scenario is being performed on environment **repl** , instance **kafka-2.repl.prod...** will be used for deletion and recreation of EBS and EC2 instance.  

### start producing messages and observing topic
* producer
```
kafka-producer-perf-test --topic mm-test \
--num-records 100000 --record-size 10 --throughput 10 \
 --producer-props bootstrap.servers=kafka-0.some.domain:9092
```
* consumer
```
kafka-console-consumer \
--bootstrap-server kafka-0.some.domain:9092 \
--topic mm-test
```
* checking the state of the topic, continously
```
watch -n2 "kafka-topics --zookeeper zk-0.some.domain:2181/kafka --describe --topic mm-test"
```

![](./images/ebs-failure-1_producing-messages.png)

### detach EBS volume
* go to the AWS console, EC2 overview and mark instance _kafka-2.repl.prod...._
![](./images/ebs-failure-2_volume-of-kafka-2.png)
* click on its block device _/dev/xvdf_ and in the pop-up on the volume id, to get to the EBS volume detail page
![](./images/ebs-failure-3_detaching-volume.png)
* from the _Actions_ drop-down choose **Force detach Volume**. Simply _Detach Volume_ will not work since it is in use by the EC2 instance.

### check Kafka Broker
the broker on instance _kafka-2.repl.prod..._ died. Sure, since its data directory disappeared.  
![](./images/ebs-failure-4_broker-state-systemctl.png)  
![](./images/ebs-failure-5_broker-error-message.png)


### check producer / consumer / partitions
after the failure on the Kafka broker, producing and consuming messages still works.  
As expected the partition assignment has changed as well as the ISR list.

![](./images/ebs-failure-6_reassigned-partitions.png)

### terminate Kafka instance
After detaching the volume forcibly it is not possible to simply start the Kafka broker again, since also its config file resides under _/kafka_. On the instance itself there is anyways no data persisted, which needs to be backuped.

Therefore it is highly recommended to start with a fresh EC2 instance + EBS volume after failure. Just terminate instance _kafka-2.repl.prod..._ via AWS management console to reach a _clean_ state.  

### recreate EBS and EC2
from within the GIT directory for environment _repl_ (_<git-root>/deployments/production/repl_) run:
* ```terraform plan``` and verify that the instance, the volume and its attachment will be created
* ```terraform apply``` to actually perform the actions

### check after recreation of EBS and EC2
as soon as the new instance is started (including the attached new EBS volume) the Kafka broker starts up and after a short time (roughly 4min, based on recovery), this broker joined back, starts re-replication and will also be back in ISR list for topic _mm-test_

![](./images/ebs-failure-7_broker-state-after-recreation.png)

![](./images/ebs-failure-8_reassigned-partitions-after-broker-recreation.png)
