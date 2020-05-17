# Introduction
This document provides step-by-step instructions for cmsweb operator regarding dns alias for k8s and VM cluster. 

Consider a case of cmsweb-test5 cluster and VM cluster (cmsweb-dev) that has one node vocms0117. The k8s cluster has two frontend nodes. In order to set DNS alias for the first time, following command can be used. 
```
openstack server set --property landb-alias="cmsweb-test5--load-0" cmsweb-test5-frontend-aa337jpo2bbf-node-0
openstack server set --property landb-alias="cmsweb-test5--load-1" cmsweb-test5-frontend-aa337jpo2bbf-node-1
```
For the VM, we can use this:
```
openstack server set --property landb-alias="cmsweb-dev--load-0" vocms0117
```
However, we want to setup DNS alias both for k8s and VM cluster simultaneously. In order to setup DNS alias both for k8s as well as VM cluster, we'll use following commands. 

```
openstack server set --property landb-alias="cmsweb-test5--load-0,cmsweb-dev--load-1" cmsweb-test5-frontend-aa337jpo2bbf-node-0
openstack server set --property landb-alias="cmsweb-test5--load-1,cmsweb-dev--load-2" cmsweb-test5-frontend-aa337jpo2bbf-node-1
```
It can be noticed that we use cmsweb-dev--load-1 with k8s cluster because load-0 is already assigned to VM vocms0117. 

However, in order to run above commands we first need to unset DNS alias for k8s cluster which can be set as follows:

```
openstack server unset --property landb-alias cmsweb-test5-frontend-aa337jpo2bbf-node-0
openstack server unset --property landb-alias cmsweb-test5-frontend-aa337jpo2bbf-node-1
```
Note: We should source the openstack RC files of project first where these VMs exist. 

Further detail is available [here](https://clouddocs.web.cern.ch/using_openstack/properties.html)

