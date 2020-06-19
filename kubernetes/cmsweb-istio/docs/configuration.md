### CMSWeb cluster configuration
This document provides details how to configure CMSWeb cluster.
All cmsweb configuration files are stored in
[cmsweb-k8s](https://gitlab.cern.ch/cmsweb-k8s/preprod.git)
repository. The are organized by directories named as corresponded services.
Each directory contains specific to the service configuration files
along with (optional) filebeat.yaml file used for log scraping.

The files located in each service configuration areas will be
mounted in corresponding pod under `/etc/secrets` area. In addition,
the robot certificates and hmac files will appear over there. The
former files are used by `proxy` crons to obtain a VOMS proxy
and later may be used by the service to validate deployment procedure.

#### frontend configuration
The frontend configuration may contain the following files:
- `cmsweb.services` file with a host URL of BE cluster
- `filebeat.yaml` filebeat configuration file
- `hostcert.pem` FE hostcert file
- `hostkey.pem` FE hostkey file

Here BE/FE stand for back-end and front-end, respectively.

If we want to exclude certain services from k8s cluster two more configuration
files are required:
- `backends.txt` file contains redirect rules to BE cluster.
The [deployment/frontend](https://github.com/dmwm/deployment/tree/master/frontend)
repository contains `backends-dev.txt`, `backends-preprod.txt` and
`backends-prod.txt` files used in VMs. For k8s you just need to supply
single `backends.txt` file with proper rules.
- `vms` file contains regexp of service with its rule, e.g. the following
rules will replace all lines with `/couch/`,
`/phedex(/` and `/phedex/datasvc/` with appropriate backends rules
```
/couch/ http://%{ENV:BACKEND}:5984
/phedex(/ http://%{ENV:BACKEND}:7101
/phedex\/datasvc/ http://%{ENV:BACKEND}:7001
```
