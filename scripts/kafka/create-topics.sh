#!/usr/bin/env bash

namespace=$1

if [[ -z $namespace ]]; then
  echo "Usage: $(basename $0) <kubernetes-namespace>"
  echo "Kafka-Topics: Namespace unset, not creating topics."
  exit 1
fi

kubectl exec --namespace $namespace -ti kafka-0 bash -- -c 'for TOPIC in \
    agency \
    agency_error \
    contract \
    contract_error \
    contract_invalid \
    contract_with_party_key \
    party \
    party_error \
    party_invalid \
    role \
    role_error \
    role_invalid \
    mdm_test \
    mdm_dev_party \
    mdm_test_party \
    mdm_prod_party \
    mdm_dev_role \
    mdm_test_role \
    mdm_prod_role \
    mdm_dev_contract \
    mdm_test_contract \
    mdm_prod_contract \
    mdm_mm_party \
    ; \
  do bin/kafka-topics.sh --create --if-not-exists --zookeeper zookeeper:2181 --topic $TOPIC --replication-factor 3 --partitions 40;\
  done'
