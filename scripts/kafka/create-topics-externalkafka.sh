#!/usr/bin/env bash

# Using confluent package or not?
# Confluent package: kafka-topics
# Apache package   : kafka-topics.sh
KAFKA_TOPICS=kafka-topics
ENV=$1

if [[ -z $ENV ]]; then
  echo "Usage: $(basename $0) <kubernetes-namespace.aws-0xxxsome.domain>"
  echo "Kafka-Topics: Namespace unset, not creating topics."
  exit 1
fi

function createtopic() {
  TOPIC=$1
  PARTITIONS=$2
  $KAFKA_TOPICS --create --if-not-exists --zookeeper zk-0.$ENV:2181/kafka --topic $TOPIC --replication-factor 3 --partitions $PARTITIONS
}

FULLTOPICS="\
    agent_permission \
    agency \
    contract \
    contract_with_party_key \
    party \
    role \
"

SMALLTOPICS="\
    agent_permission_error \
    agency_error \
    contract_error \
    contract_invalid \
    party_error \
    party_invalid \
    role_error \
    role_invalid \
"

TESTTOPICS="\
    mdm_test \
"

for TOPIC in $TESTTOPICS; do
  createtopic $TOPIC 2
done

for TOPIC in $FULLTOPICS; do
  createtopic $TOPIC 40
done

for TOPIC in $SMALLTOPICS; do
  createtopic $TOPIC 10
done
