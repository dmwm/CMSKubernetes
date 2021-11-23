#!/bin/bash

: '

# This script can be used if we get email with Subject "High number of DNS queries on k8s cluster node" and it includes following text.

For example, 

Dear Muhammad.Imran@cern.ch

You are listed as responsible for cmsweb-testbed-v1-19-sdo27lsczl75-master-0 (.cern.ch).
Our DNS servers are warning that this host has been sending a VERY HIGH
rate of queries for the last hour (88.3711111111111 requests/sec).

Please, check the cause of this problem and sort it out
since it impacts the central DNS service performance. Please
also consult http://service-dns.web.cern.ch/service-dns/faq.asp
for information on setting up dns for high demanding clients (page accessible from CERN network only).

Should this problem continue, we will have to block this system
to avoid performance problems in the central DNS service.

In order to solve this, we can run this script after pointing KUBECONFIG to the relevant cluster
' 

kubectl rollout restart deployment coredns -n kube-system
kubectl rollout restart ds k8s-keystone-auth -n kube-system
