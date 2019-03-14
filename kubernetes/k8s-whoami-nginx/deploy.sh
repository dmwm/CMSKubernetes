#!/bin/bash
#!/bin/bash
##H Usage: deploy.sh ACTION
##H
##H Available actions:
##H   help       show this help
##H   init       perform initialization for nginx ingress (TMP until label will be created in k8s)
##H   cleanup    cleanup services
##H   create     create services
##H

cluster=k8s-whoami
host=`openstack --os-project-name "CMS Webtools Mig" coe cluster show $cluster | grep node_addresses | awk '{print $4}' | sed -e "s,\[u',,g" -e "s,'\],,g"`
kubehost=`host $host | awk '{print $5}' | sed -e "s,ch.,ch,g"`
echo "Kubernetes host: $kubehost"

init()
{
    echo "### INIT ACTION ###"
    echo "+++ create new tiller resource"
    kubectl create -f tiller-rbac.yaml

    echo
    echo "+++ init tiller"
    helm init --service-account tiller --upgrade

    echo "--- delete daemon ingress-traefik"
    if [ -n "`kubectl get daemonset -n kube-system | grep ingress-traefik`" ]; then
        if [ -n "`kubectl -n kube-system get svc | grep ingress-traefik`" ]; then
            kubectl -n kube-system delete svc ingress-traefik
        fi
        if [ -n "`kubectl -n kube-system get ds | grep ingress-traefik`" ]; then
            kubectl -n kube-system delete daemonset ingress-traefik
        fi
    fi

    echo
    echo "+++ install tiller"
    helm init --history-max 200
    echo
    echo "+++ install nginx-ingress"
    helm install stable/nginx-ingress --namespace kube-system --name ingress-nginx --set rbac.create=true --values nginx-values.yaml
}

cleanup()
{
    echo "### CLEANUP ACTION ###"
    echo
    echo "--- delete secrets"
    kubectl delete secret/cluster-tls-cert
    kubectl delete secret/httpsgo-secrets
    echo
    echo "--- delete services"
    kubectl delete -f httpgo.yaml
    kubectl delete -f httpsgo.yaml
    kubectl delete -f ing-nginx.yaml
    echo
    echo "--- delete daemon ingress-traefik"
    if [ -n "`kubectl get daemonset -n kube-system | grep ingress-traefik`" ]; then
        if [ -n "`kubectl -n kube-system get svc | grep ingress-traefik`" ]; then
            kubectl -n kube-system delete svc ingress-traefik
        fi
        if [ -n "`kubectl -n kube-system get ds | grep ingress-traefik`" ]; then
            kubectl -n kube-system delete daemonset ingress-traefik
        fi
    fi
}

check()
{
    echo
    echo "*** check pods"
    kubectl get pods
    echo
    echo "*** check services"
    kubectl get svc
    echo
    echo "*** check secrets"
    kubectl get secrets
    echo
    echo "*** check ingress"
    kubectl get ing

    echo
    for ns in "kube-system" "monitoring"; do
        echo
        echo "*** check pods in $ns namespace"
        kubectl get pods -n $ns
        echo
        echo "*** check services in $ns namesapce"
        kubectl get svc -n $ns
        echo
        echo "*** check pods in $ns namespace"
        kubectl get secrets -n $ns
    done
}

create()
{
    echo "### CREATE ACTION ###"
    echo
    echo "+++ label node"
    clsname=`kubectl get nodes | tail -1 | awk '{print $1}'`
    kubectl label node $clsname role=ingress --overwrite
    kubectl get node -l role=ingress

    echo
    echo "+++ prepare secrets"
    httpsgoconfig=httpsgoconfig.json
    robot_key=/afs/cern.ch/user/v/valya/private/certificates/robotkey.pem
    robot_crt=/afs/cern.ch/user/v/valya/private/certificates/robotcert.pem
    ./make_httpsgo_secret.sh $httpsgoconfig

    echo
    echo "+++ apply secrets"
    kubectl apply -f httpsgo-secrets.yaml --validate=false
    rm *secrets.yaml

    echo
    echo "+++ create TLS secrets"
    # generate tls.key/tls.crt for custom CA
     openssl genrsa -out tls.key 3072 -config openssl.cnf; openssl req -new -x509 -key tls.key -sha256 -out tls.crt -days 730 -config openssl.cnf -subj "/CN=k8s-whoami.web.cern.ch"
    kubectl create secret tls cluster-tls-cert --key=tls.key --cert=tls.crt

    # generate tls.key/tls.crt
    #openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=k8s-whoami.web.cern.ch"
    #kubectl create secret tls cluster-tls-cert --key=tls.key --cert=tls.crt

    # create secret with our key/crt (they can be generated at ca.cern.ch/ca, see Host certificates)
    #kubectl create secret tls cluster-tls-cert --key=$cmsweb_key --cert=$cmsweb_crt

    echo
    echo "+++ deploy services"
    kubectl apply -f httpgo.yaml --validate=false
    kubectl apply -f httpsgo.yaml --validate=false
    kubectl apply -f ing-nginx.yaml --validate=false

    # we use ingress nginx and not ingress traefik
#    echo "+++ deploy traefik"
#    kubectl -n kube-system apply -f traefik.yaml --validate=false
}

# Main routine, perform action requested on command line.
case ${1:-status} in
  cleanup )
    cleanup
    ;;

  create )
    create
    ;;

  init )
    init
    check
    ;;

  check )
    check
    ;;

  help )
    perl -ne '/^##H/ && do { s/^##H ?//; print }' < $0
    ;;

  * )
    cleanup
    check
    create
    ;;
esac
