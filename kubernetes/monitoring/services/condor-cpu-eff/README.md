### Deploy

`kubectl create namespace hdfs`

`kubectl create secret generic condor-cpu-eff-secrets -n hdfs --from-file=secrets/condor-cpu-eff/keytab`

`kubectl apply -f condor-cpu-eff.yaml`

