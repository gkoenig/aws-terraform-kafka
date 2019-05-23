#!/usr/bin/env bash

kubectl exec -ti kafka-0 bin/kafka-topics.sh -- --delete --if-exists --zookeeper zookeeper:2181 --topic mytopic

