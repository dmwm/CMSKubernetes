#!/bin/bash
##H Usage: deploy.sh ACTION CONFIGURATION_AREA CERTIFICATES_AREA
##H
##H Available actions:
##H   help       show this help
##H   cleanup    cleanup services
##H   create     create services
##H   secrets    create secrets files
##H

# define help
usage="Usage: deploy.sh ACTION <CONFIGURATION_AREA> <CERTIFICATES_AREA>"
if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ] || [ "$1" == "help" ]; then
    echo $usage
    exit 1
fi

# for create/secrets actions check if conf/cert areas are provided
if [ "$1" == "create" ] || [ "$1" == "secrets" ]; then
    if [ $# -ne 3 ]; then
        echo $usage
        exit 1
    fi

    if [ -z "$2" ]; then
        echo "Please provide cmsweb configuration area to use"
        exit 1
    fi
    conf=$2
    if [ -z "$3" ]; then
        echo "Please provide certificates area to use"
        exit 1
    fi
    certificates=$3
fi

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
    echo "*** check pods"
    kubectl get pods --all-namespaces
    echo
    echo "*** check services"
    kubectl get svc --all-namespaces
    echo
    echo "*** check secrets"
    kubectl get secrets --all-namespaces
    echo
    echo "*** check ingress"
    kubectl get ing

}

secrets()
{
    # cmsweb configuration area
    conf=$1
    echo "+++ configuration: $conf"
    certificates=$2
    echo "+++ certificates : $certificates"

    # robot keys and cmsweb host certificates
    robot_key=$certificates/robotkey.pem
    robot_crt=$certificates/robotcert.pem
    cmsweb_key=$certificates/cmsweb-hostkey.pem
    cmsweb_crt=$certificates/cmsweb-hostcert.pem

    tls_key=/tmp/$USER/tls.key
    tls_crt=/tmp/$USER/tls.crt
    proxy=/tmp/$USER/proxy

    # clean-up if these files exists
    for fname in $tls_key $tls_crt $proxy; do
        if [ -f $fname ]; then
            rm $fname
        fi
    done

    # for ingress controller we need tls.key/tls.crt
    ln -s $cmsweb_key /$tls_key
    ln -s $cmsweb_key /$tls_crt

    echo "+++ generate hmac secret"
    hmac=/tmp/$USER/hmac
    perl -e 'open(R, "< /dev/urandom") or die; sysread(R, $K, 20) or die; print $K' > $hmac

    # create proxy secrets
    voms-proxy-init -voms cms -rfc \
        --key $robot_key --cert $robot_crt --out $proxy
    if [ -f $proxy ]; then
        kubectl create secret generic proxy-secrets \
            --from-file=$proxy --dry-run -o yaml | \
            kubectl apply --validate=false -f -
        rm $proxy
    fi

    echo "+++ generate secrets"
    # create secret files for deployment, they are based on
    # - robot key (pem file)
    # - robot certificate (pem file)
    # - cmsweb hostkey (pem file)
    # - cmsweb hostcert (pem file)
    # - hmac secret file
    # - configuration files from service configuration area
    for sdir in $conf/*; do
        srv=$(basename "$sdir")
        # the underscrore is not allowed in secert names
        srv=`echo $srv | sed -e "s,_,,g"`
        local files=""
        if [ -n "`ls $sdir`" ]; then
            for fname in $sdir/*; do
                files="$files --from-file=$fname"
            done
        fi
        kubectl create secret generic ${srv}-secrets \
            --from-file=$robot_key --from-file=$robot_crt \
            --from-file=$hmac \
            $files --dry-run -o yaml | \
            kubectl apply --validate=false -f -
    done

    # create ingress secrets file, it requires tls.key/tls.crt files
    kubectl create secret generic ing-secrets \
        --from-file=$tls_key --from-file=$tls_crt --dry-run -o yaml | \
        kubectl apply --validate=false -f -
    rm $hmac $tls_key $tls_crt

    # use one of the option below
    # generate tls.key/tls.crt for custom CA and openssl config
#    echo "+++ create secrets for TLS case"
#    openssl genrsa -out tls.key 3072 -config openssl.cnf; openssl req -new -x509 -key tls.key -sha256 -out tls.crt -days 730 -config openssl.cnf -subj "/CN=cmsweb-test.web.cern.ch"

    # generate tls.key/tls.crt without openssl config
    #openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=cmsweb-test.web.cern.ch"

    # create secret with our tls.key/tls.crt
#    kubectl create secret tls cluster-tls-cert --key=tls.key --cert=tls.crt

    # create secret with our key/crt (they can be generated at ca.cern.ch/ca, see Host certificates)
    # we need to use this option if ing-nginx.yaml will contain the following configuration
    # tls:
    #    - secretName: cluster-tls-cert
    echo
    echo "+++ create cluster tls secret from key=$cmsweb_key, cert=$cmsweb_crt"
    kubectl create secret tls cluster-tls-cert --key=$cmsweb_key --cert=$cmsweb_crt

    echo
    echo "+++ list sercres and configmap"
    kubectl get secrets
    kubectl -n kube-system get secrets

}

create()
{
    # adjust as necessary
    pkgs="ing-nginx frontend dbs das couchdb reqmgr2 reqmon workqueue tfaas crabcache crabserver dqmgui dmwmmon"
    pkgs="ing-nginx proxy-cron frontend dbs"

    echo "### CREATE ACTION ###"
    echo "+++ install services: $pkgs"

    echo "### DEPLOY SECRETS ###"
    # call secrets function
    secrets $1 $2

    echo
    echo "+++ list configmap"
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
    create $conf $certificates
    ;;

  secrets )
    secrets $conf $certificates
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
