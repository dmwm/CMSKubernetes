#!/bin/bash
# shellcheck disable=SC2181
set -e
##H Usage: deploy-ha.sh ACTION
##H
##H Examples:
##H    --- If CMSKubernetes, cmsmon-configs and secrets repos are in same directory ---
##H    deploy-ha.sh status
##H    deploy-ha.sh deploy-secrets
##H    deploy-ha.sh deploy-all
##H    deploy-ha.sh clean-services
##H    --- Else ---
##H    export SECRETS_D=$SOMEDIR/secrets; export CONFIGS_D=$SOMEDIR/cmsmon-configs; deploy-ha.sh ha1 status
##H
##H Arguments: ACTION should be one of the defined actions
##H Attention: this script depends on deploy-secrets.sh
##H
##H Actions:
##H   help             show this help
##H   clean-all        cleanup all services secrets storages cronjobs accounts
##H   clean-services   cleanup services
##H   clean-secrets    cleanup secrets
##H   clean-storages   cleanup storages
##H   status           check status of all cluster
##H   test             perform integration tests using VictoriaMetrics
##H   deploy-all       deploy everything
##H   deploy-secrets   deploy secrets
##H   deploy-services  deploy services
##H
##H Environments:
##H   SECRETS_D        defines secrets repository local path. (default CMSKubernetes parent dir)
##H   CONFIGS_D        defines cmsmon-configs repository local path. (default CMSKubernetes parent dir)
##H
##H READ the DOC: https://cmsmonit-docs.web.cern.ch/k8s/cluster_upgrades/#ha1
##H

unset script_dir action cluster sdir cdir deploy_secrets_sh
script_dir="$(cd "$(dirname "$0")" && pwd)"

# help definition
if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ] || [ "$1" == "help" ] || [ "$1" == "" ]; then
    grep "^##H" <"$0" | sed -e "s,##H,,g"
    exit 1
fi

action=$1

sdir=${SECRETS_D:-"${script_dir}/../../../secrets"}
cdir=${CONFIGS_D:-"${script_dir}/../../../cmsmon-configs"}

# deploy-secrets.sh temporary file
deploy_secrets_sh="$script_dir"/__temp-deploy-secrets__.sh

if [[ -z $ha || -z $action || $ha != ha*[0-9] ]]; then
    echo "ha or action is not defined. ha:${ha}, action:${action}. Exiting with help message..."
    grep "^##H" <"$0" | sed -e "s,##H,,g"
    exit 1
fi

echo "will continue with following values:"
echo "OS_PROJECT_NAME:${OS_PROJECT_NAME}, action: ${action}, secrets:${sdir}, cmsmon-configs:${cdir}"

# ------------------------------------------ CONFIG CHECKS ----------------------------------------
# Check prometheus configs
function check_configs_prometheus() {
    if [ ! -f "$cdir"/prometheus/ha/prometheus.yaml ]; then
        echo "Please provide ${cdir}/prometheus/prometheus.yaml file"
        exit 1
    fi
    # Prometheus conf should be in same directory with rules to check correctly
    cp "$cdir"/prometheus/ha/prometheus.yaml "$cdir"/prometheus/__prometheus__.yaml
    /cvmfs/cms.cern.ch/cmsmon/promtool check config "$cdir"/prometheus/__prometheus__.yaml
    if [ $? -ne 0 ]; then
        echo "Fail to validate prometheus config file"
        exit 1
    fi
    /cvmfs/cms.cern.ch/cmsmon/promtool check rules "$cdir"/prometheus/*.rules
    if [ $? -ne 0 ]; then
        echo "Fail to validate prometheus rules"
        exit 1
    fi
    # Delete temp file
    rm "$cdir"/prometheus/__prometheus__.yaml
}

# Check alertmanager configs
function check_configs_am() {
    if [ ! -f "$cdir"/alertmanager/alertmanager.yaml ]; then
        echo "Please provide ${cdir}/alertmanager/alertmanager.yaml file"
        exit 1
    fi
    /cvmfs/cms.cern.ch/cmsmon/amtool check-config "$cdir"/alertmanager/alertmanager.yaml
    if [ $? -ne 0 ]; then
        echo "Fail to validate alertmanager config file"
        exit 1
    fi
    /cvmfs/cms.cern.ch/cmsmon/amtool config routes show --config.file="${cdir}"/alertmanager/alertmanager.yaml
}

# Check status of the cluster
function cluster_check() {
    echo -e "\n*** check secrets"
    kubectl get secrets -A | grep -E "default  *|http *|alerts *" | grep Opaque
    echo -e "\n*** check svc"
    kubectl get svc -A | grep -E "default  *|http *|alerts *"
    echo -e "\n*** node status"
    kubectl top node
    echo -e "\n*** pods status"
    kubectl top pods --sort-by=memory -A | grep -E "default  *|http *|alerts *"
}

# Test VictoriaMetrics
function test_vm() {
    local url="http://cms-monitoring.cern.ch"
    local purl=${url}:30422/api/put
    local rurl=${url}:30428/api/v1/export
    echo "put data into $purl"
    curl -H 'Content-Type: application/json' -d '{"metric":"cms.test.exitCode", "value":1, "tags":{"exitCode": "8021", "site":"T2_US", "task":"test", "log":"/path/file.log"}}' "$purl"
    echo "get data from $rurl"
    curl -G "$rurl" -d 'match[]=cms.test.exitCode'
}
# =================================================================================================

# -------------------------------------- PREPARE deploy-secrets.sh -------------------------------
# Create temporary deploy-secrets.sh with correct sdir and cdir
function create_temp_deploy_secrets_sh() {
    echo "secrets dir: ${sdir}, cmsmon-configs dir: ${cdir}"
    #
    if [ ! -e "$script_dir"/deploy-secrets.sh ] || [ ! -d "$sdir" ] || [ ! -d "$cdir" ]; then
        echo "Please check if [deploy-secrets.sh:${script_dir}], [secrets:${sdir}], [cmsmon-configs:${cdir}] exist"
        exit 1
    fi
    #
    sed -e "s,cdir=cmsmon-configs.*,cdir=${cdir},g" \
        -e "s,sdir=secrets.*,sdir=${sdir},g" \
        "$script_dir"/deploy-secrets.sh >"$deploy_secrets_sh"
    chmod +x "$deploy_secrets_sh"
}

# Delete temporary deploy-secrets.sh
function rm_temp_deploy_secrets_sh() {
    rm "$deploy_secrets_sh"
}
# =================================================================================================

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function deploy_secrets() {
    create_temp_deploy_secrets_sh
    # auth
    "$deploy_secrets_sh" auth alertmanager-secrets
    "$deploy_secrets_sh" auth cern-certificates
    "$deploy_secrets_sh" auth proxy-secrets
    "$deploy_secrets_sh" auth robot-secrets
    # cpueff
    "$deploy_secrets_sh" cpueff cpueff-mongo-secrets
    # default
    "$deploy_secrets_sh" default alertmanager-secrets
    "$deploy_secrets_sh" default karma-secrets
    "$deploy_secrets_sh" default prometheus-secrets
    "$deploy_secrets_sh" default promxy-secrets
    "$deploy_secrets_sh" default proxy-secrets
    "$deploy_secrets_sh" default robot-secrets
    # http
    "$deploy_secrets_sh" http certcheck-secrets
    "$deploy_secrets_sh" http es-wma-secrets
    "$deploy_secrets_sh" http keytab-secrets
    "$deploy_secrets_sh" http krb5cc-secrets
    "$deploy_secrets_sh" http proxy-secrets
    "$deploy_secrets_sh" http robot-secrets
    #
    rm_temp_deploy_secrets_sh
}
function clean_secrets() {
    # auth
    kubectl -n auth --ignore-not-found=true delete secret auth-secrets
    kubectl -n auth --ignore-not-found=true delete secret cern-certificates
    kubectl -n auth --ignore-not-found=true delete secret proxy-secrets
    kubectl -n auth --ignore-not-found=true delete secret robot-secrets
    # cpueff
    kubectl -n cpueff --ignore-not-found=true delete secret cpueff-mongo-secrets
    # default
    kubectl -n default --ignore-not-found=true delete secret alertmanager-secrets
    kubectl -n default --ignore-not-found=true delete secret karma-secrets
    kubectl -n default --ignore-not-found=true delete secret prometheus-secrets
    kubectl -n default --ignore-not-found=true delete secret promxy-secrets
    kubectl -n default --ignore-not-found=true delete secret proxy-secrets
    kubectl -n default --ignore-not-found=true delete secret robot-secrets
    # http
    kubectl -n http --ignore-not-found=true delete secret certcheck-secrets
    kubectl -n http --ignore-not-found=true delete secret es-wma-secrets
    kubectl -n http --ignore-not-found=true delete secret keytab-secrets
    kubectl -n http --ignore-not-found=true delete secret krb5cc-secrets
    kubectl -n http --ignore-not-found=true delete secret proxy-secrets
    kubectl -n http --ignore-not-found=true delete secret robot-secrets
}
function deploy_services() {
    # Fails because of /etc/proxy/proxy tls conf
    # auth
    kubectl -n auth apply -f services/auth-proxy-server.yaml
    # cpueff
    kubectl -n cpueff apply -f services/cpueff/cpueff-goweb.yaml
    kubectl -n cpueff apply -f services/cpueff/mongo-cpueff.yaml
    # default
    kubectl -n default apply -f services/httpgo.yaml
    kubectl -n default apply -f services/karma.yaml
    kubectl -n default apply -f kmon/kube-eagle.yaml
    kubectl -n default apply -f services/promxy.yaml
    kubectl -n default apply -f services/pushgateway.yaml
    # http
    find "${script_dir}"/services/ -name "*-exp*.yaml" | awk '{print "kubectl apply -f "$1""}' | /bin/sh
}
function clean_all_services() {
    # auth
    kubectl -n auth --ignore-not-found=true delete -f services/auth-proxy-server.yaml
    # cpueff
    kubectl -n cpueff --ignore-not-found=true delete -f services/cpueff/cpueff-goweb.yaml
    kubectl -n cpueff --ignore-not-found=true delete -f services/cpueff/mongo-cpueff.yaml
    # default
    kubectl -n default --ignore-not-found=true delete -f services/alertmanager.yaml
    kubectl -n default --ignore-not-found=true delete -f services/httpgo.yaml
    kubectl -n default --ignore-not-found=true delete -f services/karma.yaml
    kubectl -n default --ignore-not-found=true delete -f kmon/kube-eagle.yaml
    kubectl -n default --ignore-not-found=true delete -f services/prometheus.yaml
    kubectl -n default --ignore-not-found=true delete -f services/promxy.yaml
    kubectl -n default --ignore-not-found=true delete -f services/pushgateway.yaml
    kubectl -n default --ignore-not-found=true delete -f services/victoria-metrics.yaml
    # http
    find "${script_dir}"/services/ -name "*-exp*.yaml" | awk '{print "kubectl --ignore-not-found=true delete -f "$1""}' | /bin/sh
}

function deploy_storage_services() {
    # Fails because of /etc/proxy/proxy tls conf
    check_configs_prometheus
    check_configs_am
    # default
    kubectl -n default apply -f services/alertmanager.yaml
    kubectl -n default apply -f services/prometheus.yaml
    kubectl -n default apply -f services/victoria-metrics.yaml
}

# cluster cronjob deployment
function deploy_cronjobs() {
    kubectl -n auth apply -f crons/cron-proxy.yaml
    kubectl -n cpueff apply -f cpueff/cpueff-spark.yaml
    kubectl -n default apply -f crons/cron-proxy.yaml
    kubectl -n http apply -f crons/cron-kerberos.yaml
    kubectl -n http apply -f crons/cron-proxy.yaml
}

function clean_cronjobs() {
    kubectl -n auth --ignore-not-found=true delete -f crons/cron-proxy.yaml
    kubectl -n cpueff --ignore-not-found=true delete -f cpueff/cpueff-spark.yaml
    kubectl -n default --ignore-not-found=true delete -f crons/cron-proxy.yaml
    kubectl -n http --ignore-not-found=true delete -f crons/cron-kerberos.yaml
    kubectl -n http --ignore-not-found=true delete -f crons/cron-proxy.yaml
}

# Deploy cinder volumes for default namespace
function deploy_storages() {
    kubectl apply -f storages/cmsmonit-cluster-cinder.yaml -n default
}
function clean_storages() {
    kubectl delete -f storages/cmsmonit-cluster-cinder.yaml -n default
}
# cluster ingress deployment
deploy_ingress()
{
    # add labels for ingress
    kubectl get node | grep node | \
        awk '{print "kubectl label node "$1" role=ingress --overwrite"}' | /bin/sh
    # deploy ingress controller
    kubectl apply -f ingress/ingress.yaml
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
namespaces="auth cpueff http "
deploy_all() {
    for _ns in $namespaces; do
        if ! kubectl get ns | grep -q $_ns; then
            kubectl create namespace $_ns
        fi
    done
    deploy_secrets
    deploy_services
}
clean_all() {
    clean_all_services
    clean_cronjobs
    sleep 10
    clean_secrets
    clean_storages
    for _ns in $namespaces; do
        if kubectl get ns | grep -q $_ns; then
            kubectl --ignore-not-found=true delete namespace $_ns
        fi
    done
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Main routine, perform action requested on command line.
case ${action:-help} in
"deploy-all")               deploy_all                            ;;
"deploy-secrets")           deploy_secrets                        ;;
"deploy-services")          deploy_services                       ;;
"deploy-storages")          deploy_storages                       ;;
"deploy-storage-services")  deploy_storage_services               ;;
"status")                   cluster_check                         ;;
"clean-all")                clean_all                             ;;
"clean-services")           clean_services                        ;;
"clean-secrets")            clean_secrets                         ;;
"clean-storages")           clean_storages                        ;;
"test")                     test_vm                               ;;
"help")                     grep "^##H" <"$0" | sed -e "s,##H,,g" ;;
*)                          grep "^##H" <"$0" | sed -e "s,##H,,g" ;;
esac
