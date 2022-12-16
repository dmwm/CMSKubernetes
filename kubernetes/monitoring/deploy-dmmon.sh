#!/bin/bash
# shellcheck disable=SC2181
set -e
##H Usage: deploy-dmmon.sh ACTION
##H
##H Examples:
##H    --- If CMSKubernetes, cmsmon-configs and secrets repos are in same directory ---
##H    deploy-dmmon.sh status
##H    deploy-dmmon.sh deploy-secrets
##H    deploy-dmmon.sh deploy-all
##H    --- Else ---
##H    export SECRETS_D=$SOMEDIR/secrets; export CONFIGS_D=$SOMEDIR/cmsmon-configs; deploy-dmmon.sh status
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
    # auth
    "$deploy_secrets_sh" auth proxy-secrets
    "$deploy_secrets_sh" auth robot-secrets
    "$deploy_secrets_sh" auth cern-certificates
    "$deploy_secrets_sh" auth dm-auth-secrets
    # datasetmon
    "$deploy_secrets_sh" datasetmon cmsmon-mongo-secrets
    #
    rm_temp_deploy_secrets_sh
}
function clean_secrets() {
    # hdfs
    kubectl -n auth --ignore-not-found=true delete secret proxy-secrets
    kubectl -n auth --ignore-not-found=true delete secret robot-secrets
    kubectl -n auth --ignore-not-found=true delete secret cern-certificates
    kubectl -n auth --ignore-not-found=true delete secret dm-auth-secrets
    # datasetmon
    kubectl -n datasetmon --ignore-not-found=true delete secret cmsmon-mongo-secrets
}

function deploy_services() {
    # auth
    # [ingress]: Don't forget to delete "cern-magnum-ingress-nginx-admission" ValidatingWebhookConfiguration
    kubectl -n auth apply -f ingress/ingress-dm.yaml
    kubectl -n auth apply -f services/auth-proxy-server-dm.yaml
    kubectl -n auth apply -f crons/cron-proxy.yaml
    # default
    kubectl -n default apply -f services/httpgo.yaml
    # datasetmon
    kubectl -n datasetmon apply -f services/datasetmon/cmsmon-mongo.yaml
    kubectl -n datasetmon apply -f services/datasetmon/rucio-mon-goweb.yaml
    kubectl -n datasetmon apply -f services/datasetmon/spark2mng.yaml
}
function clean_services() {
    # default
    kubectl -n auth --ignore-not-found=true delete -f ingress/ingress-dm.yaml
    kubectl -n auth --ignore-not-found=true delete -f services/auth-proxy-server-dm.yaml
    kubectl -n auth --ignore-not-found=true delete -f crons/cron-proxy.yaml
    # default
    kubectl -n default --ignore-not-found=true delete -f services/httpgo.yaml
    # datasetmon
    kubectl -n datasetmon --ignore-not-found=true delete -f services/datasetmon/cmsmon-mongo.yaml
    kubectl -n datasetmon --ignore-not-found=true delete -f services/datasetmon/rucio-mon-goweb.yaml
    kubectl -n datasetmon --ignore-not-found=true delete -f services/datasetmon/spark2mng.yaml
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
namespaces="auth datasetmon"
deploy_all() {
    for _ns in $namespaces; do
        if ! kubectl get ns | grep -q "$_ns"; then
            kubectl create namespace "$_ns"
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
        if kubectl get ns | grep -q "$_ns"; then
            kubectl --ignore-not-found=true delete namespace "$_ns"
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
