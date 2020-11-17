### Deploy
`kubectl create namespace rumble`

`kubectl apply -f ingress.yaml`

`kubectl create secret generic rumble-secrets -n rumble --from-file=secrets/rumble/keytab`

`kubectl apply -f rumble.yaml`

