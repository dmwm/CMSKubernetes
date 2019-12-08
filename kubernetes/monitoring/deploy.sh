#!/bin/bash
##H Usage: deploy.sh ACTION DEPLOYMENT
##H
##H Script actions:
##H   help       show this help
##H   cleanup    cleanup services
##H   create     create action
##H   status     check status of the services
##H   test       perform integration tests
##H
##H Deployments:
##H   cluster    create openstack cluster
##H   services   deploy services
##H   ingress    deploy ingress controller
##H   secrets    deploy secrets files
##H
##H Envrionments:
##H   KEY                defines name of the ssh key-pair to be used (default cloud)
##H   TMPL               defines name of the cluster template to be used (default kubernetes-1.15.3-3)
##H   CLUSTER            defines name of the cluster to be created (default monitoring-cluster)
##H   OS_PROJECT_NAME    defines name of the OpenStack project (default "CMS Web")
set -e # exit script if error occurs

# help definition
if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ] || [ "$1" == "help" ] || [ "$1" == "" ]; then
    perl -ne '/^##H/ && do { s/^##H ?//; print }' < $0
    exit 1
fi

# define action and deployment
action=$1
deployment=$2

# global definitions
project=${OS_PROJECT_NAME:-"CMS Web"}
cluster=${CLUSTER:-"monitoring-cluster"}
template=${TMPL:-"kubernetes-1.15.3-3"}
keypair=${KEY:-"cloud"}
secrets="prometheus-secrets nats-secrets"
services="prometheus pushgateway victoria-metrics nats-sub-exitcode nats-sub-stats nats-sub-t1 nats-sub-t2"

# prometheus operator deployment (so far we don't use it)
deploy_prometheus_operator()
{
    # deploy prometheus CRD
    if [ -n "`kubectl get crd | grep prometheus`" ]; then
        kubectl delete -f bundle.yaml
    fi
    kubectl apply -f bundle.yaml
    # deploy prometheus configuration
    if [ -n "`kubectl get secrets | grep prometheus-config`" ]; then
        kubectl delete secret prometheus-config
    fi
    kubectl create secret generic prometheus-config --from-file=prometheus-config.yaml
    # deploy prometheus
    if [ -n "`kubectl get pod | grep prometheus-prometheus`" ]; then
        kubectl delete -f prometheus.yaml
    fi
    kubectl apply -f prometheus.yaml
}

# cluster secrets deployment
deploy_secrets()
{
    if [ ! -d secrets ]; then
        echo "Please provide secrets area with prometheus files"
        exit 1
    fi
    if [ -n "`kubectl get secrets | grep prometheus-secrets`" ]; then
        echo "delete prometheus-secrets"
        kubectl delete secret prometheus-secrets
    fi
    ls secrets/{*.yml,*.yaml,*.json,console_libraries/*} | awk '{ORS=" "; print "--from-file="$1""}' | awk '{print "kubectl create secret generic prometheus-secrets "$0""}' | /bin/sh
    # add nats-secrets
    if [ -n "`kubectl get secrets | grep nats-secrets`" ]; then
        echo "delete nats-secrets"
        kubectl delete secret nats-secrets
    fi
    if [ ! -d nats_secrets ]; then
        echo "Please provide nats_secrets area with cms-auth, CERN_CA*.crt files"
        exit 1
    fi
    kubectl create secret generic nats-secrets \
        --from-file=nats_secrets/cms-auth \
        --from-file=nats_secrets/CERN_CA.crt \
        --from-file=nats_secrets/CERN_CA1.crt
}

# cluster storages deployment
deploy_storages()
{
    echo "+++ label node for PVC storage access"
    # label our minions in order to use PVC
    for n in `kubectl get nodes | grep -v master | grep -v NAME | awk '{print $1}'`; do
        kubectl label node $n failure-domain.beta.kubernetes.io/zone=nova --overwrite
        kubectl label node $n failure-domain.beta.kubernetes.io/region=cern --overwrite
    done
    # add PVC storage
    kubectl apply -f cinder-storage.yaml
}

# cluster services deployment
deploy_services()
{
    for svc in $services; do
        if [ -n "`kubectl get pod | grep $svc`" ]; then
            kubectl delete -f ${svc}.yaml
        fi
        kubectl apply -f ${svc}.yaml
    done

}

# cluster ingress deployment
deploy_ingress()
{
    # add labels for ingress
    kubectl get node | grep minion | \
        awk '{print "kubectl label node "$1" role=ingress --overwrite"}' | /bin/sh
    # deploy ingress controller
    kubectl apply -f ingress.yaml
}

# creation of the cluster
create()
{
    if [ "$deployment" == "cluster" ]; then
        echo
        openstack --os-project-name "$project" coe cluster template list
        openstack --os-project-name "$project" coe cluster create --keypair $keypair --cluster-template $template $cluster --node-count 2 --node-flavor=m2.2xlarge
        watch -d openstack coe cluster list
        printf "* Finished creating cluster.\n"

        printf "Setting up cluster config and context..."
        openstack coe cluster config $clustername --dir ~/.kube --force
        printf "* Finished configuring your local kubectl with your new cluster '$clustername'."

        printf "Once you created a cluster please do..."
        kubectl get node | grep minion | \
            awk '{split($1,a,"minion-"); print "openstack server set --property landb-alias=cms-prometheus--load-"a[2]"- "$1""}'
    elif [ "$deployment" == "secrets" ]; then
        deploy_secrets
    elif [ "$deployment" == "ingress" ]; then
        deploy_ingress
    else
        deploy_secrets
        deploy_storages
        deploy_services
        deploy_ingress
    fi
}

# cleanup of the cluster
cleanup()
{
    # delete all services
    for svc in $services; do
        if [ -n "`kubectl get pod | grep $svc`" ]; then
            kubectl delete -f ${svc}.yaml
        fi
    done

    # delete all secrets
    for s in $secrets; do
        if [ -n "`kubectl get secret | grep $s`" ]; then
            kubectl delete secret $s
        fi
    done

    # delete ingress
    if [ -n "`kubectl get ing`" ]; then
        kubectl delete -f ingress.yaml
    fi
}

# check status of the services
check()
{
    echo
    echo "*** check ingress"
    kubectl get ing
    echo
    echo "*** check secrets"
    kubectl get secrets
    echo
    echo "*** check pods"
    kubectl get pods
    echo
    echo "*** check services"
    kubectl get svc
    echo
    echo "*** node status"
    kubectl top node
    echo
    echo "*** pods status"
    kubectl top pods
}

test_vm()
{
    local url="http://cms-monitoring.cern.ch"
    local purl=${url}:30422/api/put
    local rurl=${url}:30428/api/v1/export
    echo "put data into $purl"
    curl -H 'Content-Type: application/json' -d '{"metric":"cms.test.exitCode", "value":1, "tags":{"exitCode": "8021", "site":"T2_US", "task":"test", "log":"/path/file.log"}}' "$purl"
    echo "get data from $rurl"
    curl -G "$rurl" -d 'match[]=cms.test.exitCode'
}

# Main routine, perform action requested on command line.
case ${1:-status} in
  cleanup )
    cleanup
    check
    ;;

  create )
    create
    ;;

  secrets )
    deploy_secrets
    ;;

  status )
    check
    ;;

  test )
    test_vm
    ;;

  help )
    perl -ne '/^##H/ && do { s/^##H ?//; print }' < $0
    ;;

  * )
    perl -ne '/^##H/ && do { s/^##H ?//; print }' < $0
    ;;
esac
