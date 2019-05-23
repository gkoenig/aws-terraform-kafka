#!/bin/bash

case "$1" in
  -h | --help)
    echo "Usage: $0 [option...] Displays list of Kubernetes ingress resources"
    echo
    echo "   csv                  CSV output for monitoring"
    echo "   html                 HTML output"
    echo "   -h, --help           this help"
    echo
    exit 0
    ;;
  html)
    template=list-html.gotemplate
    ;;
  csv)
    template=list-csv.gotemplate
    ;;
  *)
    template=list.gotemplate
    ;;
esac

kubectl get ingress,service -o go-template-file=`dirname $0`/templates/$template --sort-by='spec.rules[*].host'
