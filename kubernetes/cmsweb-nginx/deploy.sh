#!/bin/bash
##H Usage: deploy.sh ACTION
##H
##H Available actions:
##H   help       show this help
##H   cleanup    cleanup services
##H   create     create services
##H

cluster=cmsweb
host=`openstack --os-project-name "CMS Webtools Mig" coe cluster show $cluster | grep node_addresses | awk '{print $4}' | sed -e "s,\[u',,g" -e "s,'\],,g"`
kubehost=`host $host | awk '{print $5}' | sed -e "s,ch.,ch,g"`
echo "Kubernetes host: $kubehost"

cleanup()
{
    echo "### DELETE ACTION ###"
    echo "--- delete secrets"
    # new method to delete secrets
    secrets=`kubectl get secrets | grep -v NAME | grep -v default | awk '{print $1}'`
    for s in $secrets; do
        kubectl delete secret/$s
    done

    echo
    echo "--- delete services"
    services=`kubectl get svc | grep -v NAME | grep -v default | awk '{print $1}'`
    for s in $services; do
        if [ -f ${s}.yaml ]; then
            kubectl delete -f ${s}.yaml
        fi
    done

    # check if there are existing prometheus services around, if so we'll delete them
    echo
    echo "--- delete monitoring services"
    if [ -n "`kubectl -n monitoring get svc | grep prometheus-service`" ]; then
        kubectl -n monitoring delete -f kubernetes-prometheus/prometheus-service.yaml
    fi
    if [ -n "`kubectl -n monitoring get pods | grep prometheus-deployment`" ]; then
        kubectl -n monitoring delete -f kubernetes-prometheus/prometheus-deployment.yaml
    fi
    if [ -n "`kubectl -n monitoring get configmap | grep config`" ]; then
        kubectl -n monitoring delete -f kubernetes-prometheus/config-map.yaml
    fi

}

check()
{
    echo
    for ns in "monitoring" "kube-system"; do
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

    echo
    echo "*** check pods"
    kubectl get pods
    echo
    echo "*** check services"
    kubectl get svc
    echo
    echo "*** check secrets"
    kubectl get secrets
    echo "*** check ingress"
    kubectl get ing

}

create()
{
    # adjust as necessary
    pkgs="ing-nginx frontend dbs das2go httpsgo couchdb reqmgr httpsgo reqmon workqueue tfaas crabcache crabserver"

    # adjust as necessary
    user_crt=/afs/cern.ch/user/v/valya/.globus/usercert.pem
    robot_key=/afs/cern.ch/user/v/valya/private/certificates/robotkey.pem
    robot_crt=/afs/cern.ch/user/v/valya/private/certificates/robotcert.pem
    server_key=/afs/cern.ch/user/v/valya/private/certificates/server.key
    server_crt=/afs/cern.ch/user/v/valya/private/certificates/server.crt
    cmsweb_key=/afs/cern.ch/user/v/valya/private/certificates/cmsweb-hostkey.pem
    cmsweb_crt=/afs/cern.ch/user/v/valya/private/certificates/cmsweb-hostcert.pem
    dbfile=/afs/cern.ch/user/v/valya/private/dbfile
    dbssecrets=/afs/cern.ch/user/v/valya/private/DBSSecrets.py

    echo "### CREATE ACTION ###"
    echo "+++ Will install the following services: $pkgs"

    echo "+++ generate hmac secret"
    hmac=$PWD/hmac.random
    perl -e 'open(R, "< /dev/urandom") or die; sysread(R, $K, 20) or die; print $K' > $hmac

    echo
    echo "+++ prepare secrets"
    dbsconfig=dbsconfig.json
    dasconfig=dasconfig.json
    tfaasconfig=tfaas-config.json
    httpsgoconfig=httpsgoconfig.json
    ./make_das2go_secret.sh $robot_key $robot_crt $server_key $server_crt $hmac $dasconfig
    ./make_dbs_secret.sh $robot_key $robot_crt $server_key $server_crt $hmac $dbssecrets
    ./make_frontend_secret.sh $robot_key $robot_crt $server_key $server_crt $hmac
    ./make_couchdb_secret.sh $robot_key $robot_crt $server_key $server_crt $hmac
    ./make_reqmgr_secret.sh $robot_key $robot_crt $server_key $server_crt $hmac
    ./make_reqmon_secret.sh $robot_key $robot_crt $server_key $server_crt $hmac
    ./make_workqueue_secret.sh $robot_key $robot_crt $server_key $server_crt $hmac
    ./make_crabserver_secret.sh $robot_key $robot_crt $server_key $server_crt $hmac
    ./make_crabcache_secret.sh $robot_key $robot_crt $server_key $server_crt $hmac
    ./make_tfaas_secret.sh $robot_key $robot_crt $server_key $server_crt $hmac $tfaasconfig
    ./make_exporters_secret.sh $robot_key $robot_crt
    ./make_httpsgo_secret.sh $httpsgoconfig
    ./make_dbs2go_secret.sh $robot_key $robot_crt $server_key $server_crt $hmac $dbsconfig $dbfile

    for p in $pkgs; do
        echo "+++ apply secrets: $p-secrets.yaml"
        if [ -f ${p}-secrets.yaml ]; then
            kubectl apply -f ${p}-secrets.yaml --validate=false
        fi
    done
    rm *secrets.yaml $hmac

    echo "+++ create secrets for TLS case"
    # generate tls.key/tls.crt for custom CA
#    openssl genrsa -out tls.key 3072 -config openssl.cnf; openssl req -new -x509 -key tls.key -sha256 -out tls.crt -days 730 -config openssl.cnf -subj "/CN=cmsweb-test.web.cern.ch"

    # generate tls.key/tls.crt
    #openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=cmsweb-test.web.cern.ch"

    # create secret with our tls.key/tls.crt
#    kubectl create secret tls cluster-tls-cert --key=tls.key --cert=tls.crt

    # create secret with our key/crt (they can be generated at ca.cern.ch/ca, see Host certificates)
    echo
    echo "+++ create cluster tls secret from key=$cmsweb_key, cert=$cmsweb_crt"
    kubectl create secret tls cluster-tls-cert --key=$cmsweb_key --cert=$cmsweb_crt

    echo
    echo "+++ list sercres and configmap"
    kubectl get secrets
    kubectl -n kube-system get secrets
    kubectl -n kube-system get configmap

    echo
    echo "+++ label node"
    for n in `kubectl get nodes | grep -v master | grep -v NAME | awk '{print $1}'`; do
        kubectl label node $n role=ingress --overwrite
        kubectl get node -l role=ingress
    done

    echo
    echo "+++ deploy services"
    for p in $pkgs; do
        if [ -f ${p}.yaml ]; then
            kubectl apply -f ${p}.yaml --validate=false
        fi
    done

    echo "+++ deploy prometheus: https://devopscube.com/setup-prometheus-monitoring-on-kubernetes/"
    if [ ! -d "kubernetes-prometheus" ]; then
        git clone git@github.com:vkuznet/kubernetes-prometheus.git
    fi

    echo
    echo "+++ create monitoring namespace"
    if [ -z "`kubectl get namespaces | grep monitoring`" ]; then
        kubectl create namespace monitoring
    fi

    echo
    echo "+++ deploy monitoring services"
    kubectl -n monitoring apply -f kubernetes-prometheus/config-map.yaml --validate=false
    kubectl -n monitoring apply -f kubernetes-prometheus/prometheus-deployment.yaml --validate=false
    kubectl -n monitoring apply -f kubernetes-prometheus/prometheus-service.yaml --validate=false
    kubectl -n monitoring get deployments
    kubectl -n monitoring get pods
    prom=`kubectl -n monitoring get pods | grep prom | awk '{print $1}'`
    echo "### we may access prometheus locally as following"
    echo "kubectl -n monitoring port-forward $prom 8080:9090"
    echo "### to access prometheus externally we should do the following:"
    echo "ssh -S none -L 30000:$kubehost:30000 $USER@lxplus.cern.ch"
}

# Main routine, perform action requested on command line.
case ${1:-status} in
  cleanup )
    cleanup
    ;;

  create )
    create
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
