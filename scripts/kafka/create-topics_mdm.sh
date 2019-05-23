#!/usr/bin/env bash

namespace=$1

if [[ -z $namespace ]]; then
  echo "Usage: $(basename $0) <kubernetes-namespace>"
  echo "Kafka-Topics: Namespace unset, not creating topics."
  exit 1
fi

kubectl exec --namespace $namespace -ti kafka-0 bash -- -c 'for TOPIC in \
    mdm_contract \
    ; \
  do bin/kafka-topics.sh --create --if-not-exists --zookeeper zookeeper:2181 --topic $TOPIC --replication-factor 3 --partitions 20;\
  done'
