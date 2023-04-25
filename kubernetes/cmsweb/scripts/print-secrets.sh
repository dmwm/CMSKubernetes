#!/bin/bash
# helper script to print the contents of a secret in the specified namespace 

if [[ ( $# -lt 2) || ( $@ == "--help") || ( $@ == "-h") ]]; then
     echo "Usage: >>> $0 <secret-name> <namespace>"
     exit 1;
fi


secret_name=$1
namespace=$2

kubectl get secret $secret_name -n $namespace -o go-template='{{range $k,$v := .data}}{{printf "%s: " $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{{"\n"}}{{end}}'
