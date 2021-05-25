#!/bin/bash
##H Usage: deploy.sh ACTION DEPLOYMENT SECRETS_AREA
##H
##H Script actions:
##H   help        show this help
##H   cleanup     cleanup services
##H   create      create cluster with provided deployment
##H   status      check status of the services
##H
##H Deployments:
##H   cluster     create openstack cluster
##H   services    deploy services deployments and fluentd
##H   crons       deploy crons components
##H   secrets     create secrets files
##H   storages    create storages files
##H
##H Envrionments:
##H   OS_PROJECT_NAME           defines name of the OpenStack project (default "CMS Web")

# cluster name, project name, dns and namespace for spider
cluster="htcondor_spider"
cluster_ns=${OS_PROJECT_NAME:-"CMS Web"}
ns="spider"
spider_secrets="amq-username amq-password es-conf collectors"

#spider_hostname="cms-spider.cern.ch"

# define help
if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ] || [ "$1" == "help" ] || [ "$1" == "" ]; then
    perl -ne '/^##H/ && do { s/^##H ?//; print }' < "$0"
    exit 1
fi

action=$1
deployment=$2
if [ "$action" == "create" ]; then
    secrets=$3
    echo "+++ perform action     : $action"
    echo "+++ perform deployment : $deployment"
    echo "+++ use secrets dir    : $secrets"
else
    echo "+++ perform action     : $action"
fi

# dump info about our cluster
echo "openstack --os-project-name \"$cluster_ns\" coe cluster show $cluster"
hname=$(openstack --os-project-name "$cluster_ns" coe cluster show $cluster | grep node_addresses | sed -e "s,|,,g" -e "s,node_addresses,,g" -e "s, ,,g" -e "s,u,,g" -e "s,',,g" -e "s,\[,,g" -e "s,\],,g")
echo "spider cluster    : $cluster"
echo "project namespace : $cluster_ns"
echo "Kubernetes host(s): $hname"
kubectl get node

# check status of spider namespace
check()
{
    if [ "$ns" != "" ]; then
        echo
        echo "*** check pods"
        kubectl get pods -n $ns
        echo
        echo "*** check services"
        kubectl get svc -n $ns
        echo
        echo "*** check cronjobs"
        kubectl get cronjobs -n $ns
        echo
        echo "*** check secrets"
        kubectl get secrets -n $ns
        echo
        echo "*** check ingress"
        kubectl get ing -n $ns
        echo "*** check horizontal scalers"
        kubectl get hpa --all-namespaces
        echo
        echo "*** node status"
        kubectl top node
        echo
        echo "*** pods status"
        kubectl top pods -n $ns
        return
    fi
}

cleanup()
{
    echo "--- delete crons"
    kubectl delete -f cronjobs/spider-cron-affiliation.yaml
    kubectl delete -f cronjobs/spider-cron-queues.yaml

    echo "--- delete pods"
    kubectl delete -f deployments/spider-flower.yaml
    kubectl delete -f deployments/spider-worker.yaml
    kubectl delete -f deployments/spider-redis.yaml
    kubectl delete -f deployments/spider-redis-cp.yaml

    echo "--- delete services"
    kubectl delete -f service/spider-redis.yaml
    kubectl delete -f service/spider-redis-cp.yaml
    kubectl delete -f service/spider-flower.yaml

    echo "--- delete secrets"
    kubectl delete secrets amq-username -n $ns
    kubectl delete secrets amq-password -n $ns
    kubectl delete secrets es-conf -n $ns
    kubectl delete secrets collectors -n $ns

    # Be careful you may need to clear shared storages in openstack because of the quota of 50
    echo "--- delete pvc storages"
    kubectl delete -f storages/cephfs-storage.yaml

    echo "--- delete fluentd"
    kubectl delete -f s3/fluentd.yaml

    echo "--- delete accounts"
    kubectl delete -f accounts/spider-accounts.yaml

    echo "--- delete namespace"
    kubectl delete namespace $ns
    echo
    echo "+++ completely cleaned up"
}

deploy_ns()
{
    echo
    echo "+++ deploy namespace spider"
    if [ -z "$(kubectl get namespaces | grep $ns)" ]; then
        kubectl create namespace $ns
    fi
}

delete_secrets()
{
    echo
    echo "+++ delete secrets if exist"
    for sec in $spider_secrets; do
        if [ -n "$(kubectl get secrets -n $ns | grep $sec)" ]; then
            kubectl delete secrets $sec -n $ns
        fi
    done
}

deploy_secrets()
{
    delete_secrets
    echo
    echo "+++ deploy secrets"

    for sec in $spider_secrets; do
        if [ -f "$secrets"/cms-htcondor-es/"$sec" ]; then
            kubectl create secret generic "$sec" -n $ns --from-file="$secrets"/cms-htcondor-es/"$sec"
        else
            echo "Secret does not exist: $secrets/cms-htcondor-es/$sec"
        fi
    done
}

deploy_accounts()
{
    echo
    echo "+++ deploy accounts"
    kubectl apply -f accounts/spider-accounts.yaml
}

deploy_storages()
{
    echo "+++ label node for PVC storage access"
    for n in $(kubectl get nodes | grep -v master | grep -v NAME | awk '{print $1}'); do
        kubectl label node "$n" failure-domain.beta.kubernetes.io/zone=nova --overwrite
        kubectl label node "$n" failure-domain.beta.kubernetes.io/region=cern --overwrite
    done
    echo
    echo "+++ deploy pvc storages"
    kubectl apply -f storages/cephfs-storage.yaml
}

deploy_crons()
{
    echo
    echo "+++ deploy crons"
    kubectl apply -f cronjobs/spider-cron-affiliation.yaml
    kubectl apply -f cronjobs/spider-cron-queues.yaml
}

deploy_services()
{
    echo
    echo "+++ deploy services"
    kubectl apply -f service/spider-redis.yaml
    kubectl apply -f service/spider-redis-cp.yaml
    kubectl apply -f service/spider-flower.yaml
    echo "--- deploy deployments"
    kubectl apply -f deployments/spider-flower.yaml
    kubectl apply -f deployments/spider-worker.yaml
    kubectl apply -f deployments/spider-redis.yaml
    kubectl apply -f deployments/spider-redis-cp.yaml
    echo "--- deploy fluentd"
    kubectl apply -f s3/fluentd.yaml
}

create()
{
    local project=${OS_PROJECT_NAME:-"CMS Web"}
    local cluster=${SPIDER_CLUSTER:-htcondor_spider}
    local template=${CMSWEB_TMPL:-"cmsweb-template-stable"}
    local keypair=${CMSWEB_KEY:-"cloud"}
    if [ "$deployment" == "cluster" ]; then
        echo
        # Current template: cmsweb-template-v-1.19.3-20201211
        openstack --os-project-name "$project" coe cluster template list
        openstack --os-project-name "$project" coe cluster create --keypair "$keypair" --cluster-template "$template" "$cluster"
        openstack --os-project-name "$project" coe cluster list
    elif [ "$deployment" == "secrets" ]; then
        deploy_ns
        deploy_secrets
    elif [ "$deployment" == "services" ]; then
        deploy_services
    elif [ "$deployment" == "storages" ]; then
        deploy_storages
    elif [ "$deployment" == "crons" ]; then
        deploy_crons
    else
        deploy_ns
        deploy_accounts
        deploy_secrets
        deploy_storages
        sleep 20
        deploy_crons
        deploy_services
    fi
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

  status )
    check
    ;;


  help )
    perl -ne '/^##H/ && do { s/^##H ?//; print }' < "$0"
    ;;

  * )
    perl -ne '/^##H/ && do { s/^##H ?//; print }' < "$0"
    ;;
esac

