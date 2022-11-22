#!/bin/bash
##H Usage: deploy-secrets.sh NAMESPACE SECRET-NAME <HA>
##H
##H Available secrets:
##H        alerts-secrets
##H        alertmanager-secrets
##H        auth-secrets
##H        cern-certificates
##H        condor-cpu-eff-secrets
##H        hpc-usage-secrets
##H        es-wma-secrets
##H        hdfs-secrets
##H        intelligence-secrets
##H        karma-secrets
##H        keytab-secrets
##H        krb5cc-secrets
##H        log-clustering-secrets
##H        cmsmon-mongo-secrets
##H        nats-secrets
##H        prometheus-secrets
##H        promxy-secrets
##H        proxy-secrets
##H        redash-secrets
##H        robot-secrets
##H        rumble-secrets
##H        rucio-secrets
##H        rucio-daily-stats-secrets
##H        sqoop-secrets
##H        vmalert-secrets
##H Examples:
##H        deploy-secrets.sh default prometheus-secrets ha
set -e # exit script if error occurs

# help definition
if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ] || [ "$1" == "help" ] || [ "$1" == "" ]; then
    perl -ne '/^##H/ && do { s/^##H ?//; print }' < $0
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
    username=`cat $sdir/alertmanager/secrets | grep USERNAME | awk '{print $2}'`
    password=`cat $sdir/alertmanager/secrets | grep PASSWORD | awk '{print $2}'`
    content=`cat $cdir/alertmanager/alertmanager.yaml | sed -e "s,__USERNAME__,$username,g" -e "s,__PASSWORD__,$password,g"`
    literals="--from-literal=alertmanager.yaml=$content"
elif [ "$secret" == "intelligence-secrets" ]; then
    token=`cat $sdir/cmsmon-intelligence/secrets | grep TOKEN | awk '{print $2}'`
    content=`cat $cdir/cmsmon-intelligence/config.json | sed -e "s,__TOKEN__,$token,g"`
    if [ -n "$ha" ]; then
        content=`cat $cdir/cmsmon-intelligence/ha/${ha}/config.json | sed -e "s,__TOKEN__,$token,g"`
    fi
    literals="--from-literal=config.json=$content"
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
elif [ "$secret" == "robot-secrets" ]; then
    files=`ls $sdir/robot/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/robot | sed "s, $,,g"`
elif [ "$secret" == "auth-secrets" ]; then
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
    voms-proxy-init -voms cms -rfc -out /tmp/proxy
    files="--from-file=/tmp/proxy"
elif [ "$secret" == "log-clustering-secrets" ]; then
    # creds.json
    log_f=`ls $sdir/log-clustering/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/log-clustering | sed "s, $,,g"`
    # cmsmonit keytab
    cmsmonit_f=`ls $sdir/cmsmonit-keytab/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/cmsmonit-keytab | sed "s, $,,g"`
    files="${log_f} ${cmsmonit_f}"
elif [ "$secret" == "cmsmon-mongo-secrets" ]; then
    mongo_envs="MONGO_ROOT_USERNAME MONGO_ROOT_PASSWORD MONGO_USERNAME MONGO_PASSWORD MONGO_USERS_LIST"
    literals=""
    for mongo_env in $mongo_envs; do
        temp_env_val=`grep $mongo_env $sdir/cmsmon-mongo-secrets/secrets | awk '{print $2}'`
        literals="--from-literal=${mongo_env}=${temp_env_val} ${literals}"
    done
    cmsmonit_f="--from-file=${sdir}/cmsmonit-keytab/keytab"
    mongo_f=`ls $sdir/cmsmon-mongo-secrets/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/cmsmon-mongo-secrets | sed "s, $,,g"`
    files="${mongo_f} ${cmsmonit_f} ${literals}"
    # Double quoted literals variable in "kubectl create secret generic" only provide first literal because of unknown issue ...
    #   because of this we embed literals in files variable
    unset literals
elif [ "$secret" == "condor-cpu-eff-secrets" ]; then
    files=`ls $sdir/cmsmonit-keytab/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/cmsmonit-keytab | sed "s, $,,g"`
elif [ "$secret" == "hpc-usage-secrets" ]; then
    files=`ls $sdir/cmsmonit-keytab/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/cmsmonit-keytab | sed "s, $,,g"`
elif [ "$secret" == "es-wma-secrets" ]; then
    files=`ls $sdir/es-exporter/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/es-exporter | sed "s, $,,g"`
elif [ "$secret" == "hdfs-secrets" ]; then
    files=`ls $sdir/kerberos/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/kerberos | sed "s, $,,g"`
elif [ "$secret" == "keytab-secrets" ]; then
    files=`ls $sdir/kerberos/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/kerberos | sed "s, $,,g"`
elif [ "$secret" == "krb5cc-secrets" ]; then
    files=`ls $sdir/kerberos/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/kerberos | sed "s, $,,g"`
elif [ "$secret" == "nats-secrets" ]; then
    files=`ls $sdir/nats/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/nats | sed "s, $,,g"`
elif [ "$secret" == "redash-secrets" ]; then
    files=`ls $sdir/redash/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/redash | sed "s, $,,g"`
elif [ "$secret" == "rumble-secrets" ]; then
    files=`ls $sdir/rumble/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/rumble | sed "s, $,,g"`
elif [ "$secret" == "rucio-secrets" ]; then
    files=`ls $sdir/rucio/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/rucio | sed "s, $,,g"`
elif [ "$secret" == "rucio-daily-stats-secrets" ]; then
    # Grep cmsr to grep cmsr_string file only, since sqoop keytab conflicts with cmsmon keytab
    sqoop_f=`ls $sdir/sqoop/ | grep cmsr | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/sqoop | sed "s, $,,g"`
    rucio_f=`ls $sdir/rucio/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/rucio | sed "s, $,,g"`
    amq_creds_f=`ls $sdir/cms-rucio-dailystats/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/cms-rucio-dailystats | sed "s, $,,g"`
    cmsmonit_f="--from-file=${sdir}/cmsmonit-keytab/keytab"
    # To test, add cms-training amq creds json as different name. pem files should be in /etc/secrets directory!
    amq_training_creds_f="--from-file=amq_broker_training.json=${sdir}/cms-training/amq_broker.json"
    amq_training_cert="--from-file=${sdir}/cms-training/robot-training-cert.pem"
    amq_training_key="--from-file=${sdir}/cms-training/robot-training-key.pem"
    files="${sqoop_f} ${rucio_f} ${amq_creds_f} ${cmsmonit_f} ${amq_training_creds_f} ${amq_training_cert} ${amq_training_key}"
elif [ "$secret" == "sqoop-secrets" ]; then
    s_files=`ls $sdir/sqoop/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/sqoop | sed "s, $,,g"`
    c_files=`ls $cdir/sqoop/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$cdir/sqoop | sed "s, $,,g"`
    rucio_f=`ls $sdir/rucio/ | awk '{ORS=" " ; print "--from-file="D"/"$1""}' D=$sdir/rucio | sed "s, $,,g"`
    files="${s_files} ${c_files} ${rucio_f}"
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
