#!/bin/bash
# shellcheck disable=SC2181
set -e
##H Usage: deploy-cron.sh ACTION
##H
##H Examples:
##H    --- If CMSKubernetes, cmsmon-configs and secrets repos are in same directory ---
##H    deploy-cron.sh status
##H    deploy-cron.sh deploy-secrets
##H    deploy-cron.sh deploy-all
##H    deploy-cron.sh clean-services
##H    --- Else ---
##H    export SECRETS_D=$SOMEDIR/secrets; export CONFIGS_D=$SOMEDIR/cmsmon-configs; deploy-cron.sh status
##H
##H Attention: this script depends on deploy-secrets.sh
##H
##H Actions:
##H   help             show this help
##H   clean-all        cleanup all services secrets cronjobs accounts
##H   clean-services   cleanup services
##H   clean-secrets    cleanup secrets
##H   clean-storages   cleanup storages
##H   status           check status of all cluster
##H   deploy-all       deploy everything
##H   deploy-secrets   deploy secrets
##H   deploy-services  deploy services
##H
##H Environments:
##H   SECRETS_D        defines secrets repository local path. (default CMSKubernetes parent dir)
##H   CONFIGS_D        defines cmsmon-configs repository local path. (default CMSKubernetes parent dir)

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

if [[ -z $action ]]; then
    echo "action is not defined. action:${action}. Exiting with help message..."
    grep "^##H" <"$0" | sed -e "s,##H,,g"
    exit 1
fi

echo "will continue with following values:"
echo "OS_PROJECT_NAME:${OS_PROJECT_NAME}, action: ${action}, secrets:${sdir}, cmsmon-configs:${cdir}"

# ------------------------------------------ CHECKS -----------------------------------------------
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
    kubectl get pods -A | grep -E "default  *|http *|alerts *"
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
    # hdfs
    "$deploy_secrets_sh" hdfs proxy-secrets
    "$deploy_secrets_sh" hdfs robot-secrets
    "$deploy_secrets_sh" hdfs rucio-daily-stats-secrets
    "$deploy_secrets_sh" hdfs condor-cpu-eff-secrets
    "$deploy_secrets_sh" hdfs hpc-usage-secrets
    "$deploy_secrets_sh" hdfs cron-size-quotas-secrets
    "$deploy_secrets_sh" hdfs cron-spark-jobs-secrets
    #
    rm_temp_deploy_secrets_sh
}
function clean_secrets() {
    # hdfs
    kubectl -n hdfs --ignore-not-found=true delete secret proxy-secrets
    kubectl -n hdfs --ignore-not-found=true delete secret robot-secrets
    kubectl -n hdfs --ignore-not-found=true delete secret rucio-daily-stats-secrets
    kubectl -n hdfs --ignore-not-found=true delete secret condor-cpu-eff-secrets
    kubectl -n hdfs --ignore-not-found=true delete secret hpc-usage-secrets
    kubectl -n hdfs --ignore-not-found=true delete secret cron-size-quotas-secrets
    kubectl -n hdfs --ignore-not-found=true delete secret cron-spark-jobs-secrets
}

function deploy_services() {
    # default
    kubectl -n default apply -f services/pushgateway.yaml
    # hdfs
    kubectl -n hdfs apply -f crons/cron-proxy.yaml
    kubectl -n hdfs apply -f services/cmsmon-hpc-usage.yaml
    kubectl -n hdfs apply -f services/cmsmon-rucio-ds.yaml
    kubectl -n hdfs apply -f services/condor-cpu-eff.yaml
    kubectl -n hdfs apply -f services/cron-size-quotas.yaml
    kubectl -n hdfs apply -f services/cron-spark-jobs.yaml
}
function clean_services() {
    # default
    kubectl -n default --ignore-not-found=true delete -f services/pushgateway.yaml
    # hdfs
    kubectl -n hdfs --ignore-not-found=true delete -f crons/cron-proxy.yaml
    kubectl -n hdfs --ignore-not-found=true delete -f services/cmsmon-hpc-usage.yaml
    kubectl -n hdfs --ignore-not-found=true delete -f services/cmsmon-rucio-ds.yaml
    kubectl -n hdfs --ignore-not-found=true delete -f services/condor-cpu-eff.yaml
    kubectl -n hdfs --ignore-not-found=true delete -f services/cron-size-quotas.yaml
    kubectl -n hdfs --ignore-not-found=true delete -f services/cron-spark-jobs.yaml
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
namespaces="hdfs"
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
    clean_services
    sleep 10
    clean_secrets
    for _ns in $namespaces; do
        if kubectl get ns | grep -q $_ns; then
            kubectl --ignore-not-found=true delete namespace $_ns
        fi
    done

}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Main routine, perform action requested on command line.
case ${action:-help} in
"deploy-all")       deploy_all                            ;;
"deploy-secrets")   deploy_secrets                        ;;
"deploy-services")  deploy_services                       ;;
"status")           cluster_check                         ;;
"clean-all")        clean_all                             ;;
"clean-services")   clean_services                        ;;
"clean-secrets")    clean_secrets                         ;;
"help")             grep "^##H" <"$0" | sed -e "s,##H,,g" ;;
*)                  grep "^##H" <"$0" | sed -e "s,##H,,g" ;;
esac
