# Ingress debug

```shell
# follow infress-nginx-controller logs
/cvmfs/cms.cern.ch/cmsmon/stern -n kube-system cern-magnum-ingress-nginx-controller

# follow auth-proxy-server logs
/cvmfs/cms.cern.ch/cmsmon/stern -n auth auth-proxy-server

# Not complete but some part is important(i.e.: cluster creation node labels)
# Do not use exact ingress definition, additional annotations are required
https://clouddocs.web.cern.ch/containers/tutorials/lb.html#cluster-setup 
```
