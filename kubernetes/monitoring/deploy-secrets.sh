#!/bin/bash
set -e
##H Usage: deploy-secrets.sh NAMESPACE SECRET-NAME <HA>
##H
##H Used by deploy-ha.sh script
##H
##H Available secrets:
##H        alerts-secrets
##H        alertmanager-secrets
##H        auth-secrets
##H        cern-certificates
##H        certcheck-secrets
##H        cms-eos-mon-secrets
##H        cpueff-mongo-secrets
##H        cron-size-quotas-secrets
##H        cron-spark-jobs-secrets
##H        es-wma-secrets
##H        hpc-usage-secrets
##H        karma-secrets
##H        keytab-secrets
##H        krb5cc-secrets
##H        prometheus-secrets
##H        promxy-secrets
##H        proxy-secrets
##H        redash-secrets
##H        robot-secrets
##H        rucio-daily-stats-secrets
##H        s3-keys-secrets
##H        sqoop-secrets
##H        vmalert-secrets
##H        grafana-backup-secrets
##H        udp-secrets
##H        rucio-datasets-monitoring-secrets
##H Examples:
##H        deploy-secrets.sh default prometheus-secrets ha

# help definition
if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ] || [ "$1" == "help" ] || [ "$1" == "" ]; then
    grep "^##H" <"$0" | sed -e "s,##H,,g"
    exit 1
fi

# define configuration and secrets areas
cdir=cmsmon-configs
sdir=secrets

# --- DO NOT CHANGE BELOW THIS LINE --- #
ns=$1
secret=$2
ha=""
if [ $# == 3 ]; then
    ha=$3
fi
echo "config dir: $cdir"
echo "secret dir: $sdir"
echo "Deploying $secret into $ns namespace, ha=\"$ha\""
# there are two parameters we define for each secret
# files should contain list of files in a form --from-file=file1 --from-file=file2
files=""
# literals can contain key=value pair, e.g. --from-literal=hmac=val
literals=""

if [ "$secret" == "prometheus-secrets" ]; then
    prom="$cdir/prometheus/prometheus.yaml"
    if [ $ha != "" ]; then
        prom="$cdir/prometheus/ha/prometheus.yaml"
    fi
    files=`ls $cdir/prometheus/*.rules $cdir/prometheus/*.json $prom | awk '{ORS=" " ; print "--from-file="$1""}' | sed "s, $,,g"`
elif [ "$secret" == "alertmanager-secrets" ]; then
    files="--from-file=${cdir}/alertmanager/alertmanager.yaml"
elif [ "$secret" == "karma-secrets" ]; then
    files="--from-file=$cdir/karma/karma.yaml"
    if [ "$ha" == "ha1" ]; then
        files="--from-file=$cdir/karma/ha1/karma.yaml"
    elif [ "$ha" == "ha2" ]; then
        files="--from-file=$cdir/karma/ha2/karma.yaml"
    fi
elif [ "$secret" == "promxy-secrets" ]; then
    files=`ls $cdir/promxy/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$cdir/promxy | sed "s, $,,g"`
elif [ "$secret" == "vmalert-secrets" ]; then
    files=`ls $cdir/vmalert/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$cdir/vmalert | sed "s, $,,g"`
elif [ "$secret" == "grafana-backup-secrets" ]; then
    token="--from-file=${sdir}/grafana-backup/token.json"
    cmsmonit_k="--from-file=${sdir}/cmsmonit-keytab/keytab"
    files="${token} ${cmsmonit_k}"
elif [ "$secret" == "udp-secrets" ]; then
    files="--from-file=${sdir}/udp/udp_server.json"
elif [ "$secret" == "s3-keys-secrets" ]; then
    files=`ls $sdir/victoria-metrics/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/victoria-metrics | sed "s, $,,g"`
elif [ "$secret" == "robot-secrets" ]; then
    files=`ls $sdir/robot/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/robot | sed "s, $,,g"`
elif [ "$secret" == "auth-secrets" ]; then
    _s_dir=$sdir/cmsmon-auth
    if [ ! -e $_s_dir/hmac ] || [ ! -e $_s_dir/tls.crt  ] || [ ! -e $_s_dir/tls.key  ]; then
        # Can be in https://gitlab.cern.ch/cmsweb-k8s-admin/k8s_admin_config, or copy from old cluster.
        echo "Please make sure hmac, tls.crt and tls.key are copied from cms-monitoring cluster secrets. Exiting..."
        exit 1
    fi
    files=`ls $sdir/cmsmon-auth/ | egrep -v "config.json|secrets$" | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/cmsmon-auth | sed "s, $,,g"`
    clientID=`cat $sdir/cmsmon-auth/secrets | grep CLIENT_ID | awk '{print $2}'`
    clientSECRET=`cat $sdir/cmsmon-auth/secrets | grep CLIENT_SECRET | awk '{print $2}'`
    content=`cat $cdir/cmsmon-auth/config.json | sed -e "s,__CLIENT_ID__,$clientID,g" -e "s,__CLIENT_SECRET__,$clientSECRET,g"`
    literals="--from-literal=config.json=$content"
elif [ "$secret" == "cern-certificates" ]; then
    files=`ls $sdir/CERN_CAs/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/CERN_CAs | sed "s, $,,g"`
elif [ "$secret" == "alerts-secrets" ]; then
    files=`ls $sdir/alerts/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/alerts | sed "s, $,,g"`
elif [ "$secret" == "proxy-secrets" ]; then
    unset temp_proxy _robot_crt _robot_key
    temp_proxy=/tmp/$USER/proxy
    _robot_crt=$sdir/robot/robotcert.pem
    _robot_key=$sdir/robot/robotkey.pem
    voms-proxy-init -voms cms -rfc --key $_robot_key --cert $_robot_crt -valid 95:50 --out "$temp_proxy"
    files="--from-file=${temp_proxy}"
elif [ "$secret" == "cpueff-mongo-secrets" ]; then
    mongo_envs="MONGO_ROOT_USERNAME MONGO_ROOT_PASSWORD MONGO_USERNAME MONGO_PASSWORD MONGO_USERS_LIST"
    literals=""
    for mongo_env in $mongo_envs; do
        temp_env_val=$(grep "$mongo_env" $sdir/cpueff-mongo-secrets/secrets | awk '{print $2}')
        literals="--from-literal=${mongo_env}=${temp_env_val} ${literals}"
    done
    cmsmonit_f="--from-file=${sdir}/cmsmonit-keytab/keytab"
    mongo_f=$(ls $sdir/cpueff-mongo-secrets/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/cpueff-mongo-secrets | sed "s, $,,g")
    files="${mongo_f} ${cmsmonit_f} ${literals}"
    unset literals
elif [ "$secret" == "cron-size-quotas-secrets" ]; then
    files="--from-file=${sdir}/cmsmonit-keytab/keytab"
elif [ "$secret" == "cron-spark-jobs-secrets" ]; then
    # file in secrets mount : keytab          -> cmsmonit-keytab
    cmsmonit_k="--from-file=${sdir}/cmsmonit-keytab/keytab"
    test_tenant_secret="--from-file=${sdir}/es-cms-opensearch/test_tenant_secret"
    files="${cmsmonit_k} ${test_tenant_secret}"
elif [ "$secret" == "cms-eos-mon-secrets" ]; then
    files="--from-file=${sdir}/cms-eos-mon/amq_broker.json"
elif [ "$secret" == "hpc-usage-secrets" ]; then
    files=`ls $sdir/cmsmonit-keytab/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/cmsmonit-keytab | sed "s, $,,g"`
elif [ "$secret" == "es-wma-secrets" ]; then
    files=`ls $sdir/es-exporter/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/es-exporter | sed "s, $,,g"`
elif [ "$secret" == "keytab-secrets" ]; then
    files="--from-file=${sdir}/cmssqoop-keytab/keytab --from-file=${sdir}/kerberos/krb5cc"
elif [ "$secret" == "krb5cc-secrets" ]; then
    files="--from-file=${sdir}/cmssqoop-keytab/keytab --from-file=${sdir}/kerberos/krb5cc"
elif [ "$secret" == "redash-secrets" ]; then
    files=`ls $sdir/redash/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/redash | sed "s, $,,g"`
elif [ "$secret" == "rucio-daily-stats-secrets" ]; then
    amq_creds_f=`ls $sdir/cms-rucio-dailystats/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/cms-rucio-dailystats | sed "s, $,,g"`
    cmsmonit_f="--from-file=${sdir}/cmsmonit-keytab/keytab"
    # To test, add cms-training amq creds json as different name. pem files should be in /etc/secrets directory!
    amq_training_creds_f="--from-file=amq_broker_training.json=${sdir}/cms-training/amq_broker.json"
    amq_training_cert="--from-file=${sdir}/cms-training/robot-training-cert.pem"
    amq_training_key="--from-file=${sdir}/cms-training/robot-training-key.pem"
    files="${amq_creds_f} ${cmsmonit_f} ${amq_training_creds_f} ${amq_training_cert} ${amq_training_key}"
elif [ "$secret" == "rucio-datasets-monitoring-secrets" ]; then
    cmsmonit_k="--from-file=${sdir}/cmsmonit-keytab/keytab"
    cms_rucio_secret="--from-file=${sdir}/es-cms-opensearch/cms_rucio_secret"
    files="${cmsmonit_k} ${cms_rucio_secret}"
elif [ "$secret" == "sqoop-secrets" ]; then
    cmssqoop_f="--from-file=${sdir}/cmssqoop-keytab/keytab"
    s_files=`ls $sdir/sqoop/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/sqoop | sed "s, $,,g"`
    c_files=`ls $cdir/sqoop/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$cdir/sqoop | sed "s, $,,g"`
    rucio_f=`ls $sdir/rucio/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/rucio | sed "s, $,,g"`
    files="${cmssqoop_f} ${s_files} ${c_files} ${rucio_f}"
elif [ "$secret" == "certcheck-secrets" ]; then
    robot_s="--from-file=cmsmonit_cert=${sdir}/robot/robotcert.pem"
    robot_s="--from-file=cmsmonit_key=${sdir}/robot/robotkey.pem ${robot_s}"
    #
    cms_monitoring_s="--from-file=cms_monitoring_cert=${sdir}/cmsmon-auth/tls.crt"
    cms_monitoring_s="--from-file=cms_monitoring_key=${sdir}/cmsmon-auth/tls.key ${cms_monitoring_s}"
    #
    cms_dm_monitoring_s="--from-file=cms_dm_monitoring_cert=${sdir}/cms-dm-monitoring-auth/tls.crt"
    cms_dm_monitoring_s="--from-file=cms_dm_monitoring_key=${sdir}/cms-dm-monitoring-auth/tls.key ${cms_dm_monitoring_s}"
    #
    cmsmonit_k="--from-file=cmsmonit_keytab=${sdir}/cmsmonit-keytab/keytab"
    cmssqoop_k="--from-file=cmssqoop_keytab=${sdir}/cmssqoop-keytab/keytab"
    training_s="--from-file=${sdir}/cms-training/robot-training-cert.pem --from-file=${sdir}/cms-training/robot-training-key.pem"
    files="${robot_s} ${cms_monitoring_s} ${cms_dm_monitoring_s} ${cmsmonit_k} ${cmssqoop_k} ${training_s}"
fi
echo "files: \"$files\""
#echo "literals: $literals"
if [ -n "`kubectl get secrets -n $ns | grep $secret`" ]; then
    kubectl -n $ns delete secret $secret
fi
if [ -n "$literals" ]; then
    kubectl create secret generic $secret $files "$literals" --dry-run=client -o yaml | kubectl apply --namespace=$ns -f -
else
    kubectl create secret generic $secret $files --dry-run=client -o yaml | kubectl apply --namespace=$ns -f -
fi
kubectl describe secrets $secret -n $ns
