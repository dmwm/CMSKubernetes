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
secrets="prometheus-secrets nats-secrets spider-specrets udp-secrets"
services="prometheus pushgateway victoria-metrics victoria-metrics-test nats-sub-exitcode nats-sub-stats nats-sub-t1 nats-sub-t2 udp-server"
namespaces="udp nats spider"

# prometheus operator deployment (so far we don't use it)
deploy_prometheus_operator()
{
    # deploy prometheus CRD
    if [ -n "`kubectl get crd | grep prometheus`" ]; then
        kubectl delete -f crd/prometheus/bundle.yaml
    fi
    kubectl apply -f crd/prometheus/bundle.yaml
    # deploy prometheus configuration
    if [ -n "`kubectl get secrets | grep prometheus-config`" ]; then
        kubectl delete secret prometheus-config
    fi
    kubectl create secret generic prometheus-config --from-file=crd/prometheus/prometheus-config.yaml
    # deploy prometheus
    if [ -n "`kubectl get pod | grep prometheus-prometheus`" ]; then
        kubectl delete -f crd/prometheus/prom-oper.yaml
    fi
    kubectl apply -f crd/prometheus/prom-oper.yaml
}

# cluster secrets deployment
deploy_secrets()
{
    # add prometheus secrets
    if [ ! -d secrets/prometheus ]; then
        echo "Please provide secrets/prometheus area with prometheus files"
        exit 1
    fi
    if [ -n "`kubectl get secrets | grep prometheus-secrets`" ]; then
        echo "delete prometheus-secrets"
        kubectl delete secret prometheus-secrets
    fi
    ls secrets/prometheus/{*.yaml,*.json,console_libraries/*,*.rules} | awk '{ORS=" "; print "--from-file="$1""}' | awk '{print "kubectl create secret generic prometheus-secrets "$0""}' | /bin/sh
    if [ -n "`kubectl get secrets | grep prometheus-test-secrets`" ]; then
        echo "delete prometheus-test-secrets"
        kubectl delete secret prometheus-test-secrets
    fi
    ls secrets/prometheus/{*.yaml,*.json,console_libraries/*,*.rules} | awk '{ORS=" "; print "--from-file="$1""}' | awk '{print "kubectl create secret generic prometheus-test-secrets "$0""}' | /bin/sh

    # add alermanager secrets
    if [ ! -d secrets/alertmanager ]; then
        echo "Please provide secrets/alertmanager area with alermanager files"
        exit 1
    fi
    if [ -n "`kubectl get secrets | grep alertmanager-secrets`" ]; then
        echo "delete alertmanager-secrets"
        kubectl delete secret alertmanager-secrets
    fi
    ls secrets/alertmanager/*.yaml | awk '{ORS=" "; print "--from-file="$1""}' | awk '{print "kubectl create secret generic alertmanager-secrets "$0""}' | /bin/sh

    # add nats-secrets
    if [ -n "`kubectl -n nats get secrets | grep nats-secrets`" ]; then
        echo "delete nats-secrets"
        kubectl -n nats delete secret nats-secrets
    fi
    if [ ! -d secrets/nats ]; then
        echo "Please provide secrets/nats area with cms-auth, CERN_CA*.crt files"
        exit 1
    fi
    kubectl -n nats create secret generic nats-secrets \
        --from-file=secrets/nats/cms-auth \
        --from-file=secrets/nats/CERN_CA.crt \
        --from-file=secrets/nats/CERN_CA1.crt

    # add spider secrets
    if [ -n "`kubectl -n spider get secrets | grep spider-secrets`" ]; then
        echo "delete spider-secrets"
        kubectl -n spider delete secret spider-secrets
    fi
    if [ ! -d secrets/cms-htcondor-es ]; then
        echo "Please provide secrets/cms-htcondor-es area with collectors.json file"
        exit 1
    fi
    kubectl -n spider create secret generic spider-secrets --from-file=secrets/cms-htcondor-es/collectors.json

    # add udp secrets
    if [ -n "`kubectl -n udp get secrets | grep udp-secrets`" ]; then
        echo "delete udp-secrets"
        kubectl -n udp delete secret udp-secrets
    fi
    kubectl -n udp create secret generic udp-secrets --from-file=secrets/udp/udp_server.json
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
    if [ -z "`kubectl get pvc | grep cinder-volume-claim`" ]; then
        kubectl apply -f storages/cinder-storage.yaml
    fi
    if [ -z "`kubectl get pvc | grep prometheus-volume-claim`" ]; then
        kubectl apply -f storages/prometheus-storage.yaml
    fi
}

# cluster services deployment
deploy_services()
{
    for svc in $services; do
        if [ -n "`kubectl get pod | grep $svc`" ]; then
            kubectl delete -f services/${svc}.yaml
        fi
        kubectl apply -f services/${svc}.yaml
    done

}

# cluster ingress deployment
deploy_ingress()
{
    # add labels for ingress
    kubectl get node | grep minion | \
        awk '{print "kubectl label node "$1" role=ingress --overwrite"}' | /bin/sh
    # deploy ingress controller
    kubectl apply -f ingress/ingress.yaml
}

# deploy roles for our cluster
deploy_roles()
{
    kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
}

# deploy metrics server and kube-eagle to monitor the cluster
deploy_kmon()
{
    if [ ! -d metrics-server ]; then
        git clone git@github.com:kubernetes-sigs/metrics-server.git
    fi
    local metrics=`kubectl -n kube-system get pods | grep metrics-server`
    if [ -z "$metrics" ] && [ -d metrics-server/deploy/1.8+/ ]; then
        kubectl create -f metrics-server/deploy/1.8+/
    fi
    local keagle=`kubectl get pods | grep metrics-server`
    if [ -z "$keagle" ]; then
        kubectl apply -f kmon/kube-eagle.yaml
    fi
}

# create namespaces
deploy_namespaces()
{
    for ns in $namespaces; do
        kubectl create namespace $ns
    done
}

# creation of the cluster
create()
{
    if [ "$deployment" == "cluster" ]; then
        echo
        openstack --os-project-name "$project" coe cluster template list
        openstack --os-project-name "$project" coe cluster create --keypair $keypair --cluster-template $template $cluster --node-count 2 --flavor=m2.2xlarge
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
        deploy_namespaces
        deploy_secrets
        deploy_storages
        deploy_services
        deploy_roles
        deploy_kmon
        deploy_ingress
    fi
}

# cleanup of the cluster
cleanup()
{
    # delete all services
    for svc in $services; do
        if [ -n "`kubectl get pod | grep $svc`" ]; then
            kubectl delete -f services/${svc}.yaml
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
        kubectl delete -f ingress/ingress.yaml
    fi

    # delete monitoring parts
    if [ -n "`kubectl get pod | grep kube-eagle`" ]; then
        kubectl delete -f kmon/kube-eagle.yaml
    fi

    # delete metrics-server
    local metrics=`kubectl -n kube-system get pods | grep metrics-server`
    if [ -n "$metrics" ] && [ -d metrics-server/deploy/1.8+/ ]; then
        kubectl delete -f metrics-server/deploy/1.8+/
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
