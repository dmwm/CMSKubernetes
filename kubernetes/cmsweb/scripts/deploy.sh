#!/bin/bash
##H Usage: deploy.sh ACTION DEPLOYMENT CONFIGURATION_AREA CERTIFICATES_AREA HMAC
##H
##H Script actions:
##H   help       show this help
##H   cleanup    cleanup services
##H   create     create cluster with provided deployment
##H   scale      scale given deployment services
##H   status     check status of the services
##H
##H Deployments:
##H   cluster    create openstack cluster
##H   services   deploy services cluster
##H   default_services   deploy services cluster
##H   frontend   deploy frontend cluster
##H   daemonset  deploy cluster's daemonsets
##H   aps	 deploy auth-proxy-servers as frontends
##H   ingress    deploy ingress controller
##H   monitoring_frontend deploy monitoring components in frontend services
##H   monitoring_backend deploy monitoring components as backend services
##H   monitoring_aps deploy monitoring components in aps clusters
##H   crons      deploy crons components
##H   secrets    create secrets files
##H   storages   create storages
##H
##H Envrionments:
##H   CMSWEB_CLUSTER            defines name of the cluster to be created (default cmsweb)
##H   OS_PROJECT_NAME           defines name of the OpenStack project (default "CMS Web")
##H   CMSWEB_HOSTNAME           defines cmsweb hostname (default cmsweb-test.cern.ch)
##H   CMSWEB_HOSTNAME_FRONTEND  defines cmsweb FE hostname (default cmsweb-test.cern.ch)
##H   CMSWEB_ENV                defines cmsweb environemnt, e.g. production, preproduction (default "")

# common definitions (adjust if necessary)
cluster=${CMSWEB_CLUSTER:-cmsweb}
cluster_ns=${OS_PROJECT_NAME:-"CMS Web"}
cmsweb_hostname=${CMSWEB_HOSTNAME:-cmsweb-srv.cern.ch}
cmsweb_hostname_frontend=${CMSWEB_HOSTNAME_FRONTEND:-cmsweb-test.cern.ch}
cmsweb_image_tag=${CMSWEB_IMAGE_TAG:-:latest}



env_prefix="k8s"
prod_prefix="#PROD#"
# we define logs_prefix as empty for all use-cases
logs_prefix=""
# we'll use specific logs_prefix on preproduction and production deployment and this will be used for cephfs shares
if [ "$CMSWEB_ENV" == "production" ] || [ "$CMSWEB_ENV" == "prod" ]; then
    prod_prefix="      " # will replace '#PROD#' prefix
    logs_prefix="-prod" # will append this prefix to logs-cephfs-claim
    env_prefix="k8s-prod" # will replace k8s #k8s# part
fi
if [ "$CMSWEB_ENV" == "preproduction" ] || [ "$CMSWEB_ENV" == "preprod" ]; then
    prod_prefix="      " # will replace '#PROD#' prefix
    logs_prefix="-preprod" # will append this prefix to logs-cephfs-claim
    env_prefix="k8s-preprod" # will replace k8s #k8s# part
fi

if [ "$env_prefix" != "k8s-preprod" ] && [  "$env_prefix" != "k8s-prod" ]; then

    cluster_name=`kubectl config get-clusters | grep -v NAME`
    if [[ "$cluster_name" == *"cmsweb-auth"* ]] ; then
                env_prefix="auth"
    fi
    if [[ "$cluster_name" == *"cmsweb-test1"* ]] ; then
                env_prefix="test1"
    fi
    if [[ "$cluster_name" == *"cmsweb-test2"* ]] ; then
                env_prefix="test2"
    fi
    if [[ "$cluster_name" == *"cmsweb-test3"* ]] ; then
                env_prefix="test3"
    fi
    if [[ "$cluster_name" == *"cmsweb-test4"* ]] ; then
                env_prefix="test4"
    fi
    if [[ "$cluster_name" == *"cmsweb-test5"* ]] ; then
                env_prefix="test5"
    fi
    if [[ "$cluster_name" == *"cmsweb-test6"* ]] ; then
                env_prefix="test6"
    fi
    if [[ "$cluster_name" == *"cmsweb-test7"* ]] ; then
                env_prefix="test7"
    fi
    if [[ "$cluster_name" == *"cmsweb-test8"* ]] ; then
                env_prefix="test8"
    fi
    if [[ "$cluster_name" == *"cmsweb-test9"* ]] ; then
                env_prefix="test9"
    fi
    if [[ "$cluster_name" == *"cmsweb-test10"* ]] ; then
                env_prefix="test10"
    fi
    if [[ "$cluster_name" == *"cmsweb-test11"* ]] ; then
                env_prefix="test11"
    fi
    if [[ "$cluster_name" == *"cmsweb-test12"* ]] ; then
                env_prefix="test12"
    fi
    env_prefix="k8s-$env_prefix"
fi
    echo "#### env_prefix = $env_prefix"

sdir=services
mdir=monitoring
idir=ingress
cdir=crons
ddir=daemonset


# cmsweb service namespaces
#cmsweb_ns=`grep namespace $sdir/* | awk '{print $3}' | sort | uniq | grep -v default | grep -v phedex | grep -v couchdb | grep -v dqm | grep -v auth | grep -v mongodb | grep -v udp | grep -v tfaas`
cmsweb_ns="auth default couchdb crab das dbs dmwm dqm http ruciocm tzero wma"
# services for cmsweb cluster, adjust if necessary
#cmsweb_ing="ing-srv"
#cmsweb_ing="ing-couchdb ing-crab ing-dbs ing-das ing-dmwm ing-dqm ing-http ing-phedex ing-tzero ing-exitcodes"
cmsweb_ing="ing-crab ing-dbs ing-das ing-dmwm ing-dqm ing-dqm-offline ing-http ing-ruciocm ing-tzero ing-wma"
cmsweb_ds="frontend-ds"

cmsweb_aps="auth-proxy-server scitokens-proxy-server x509-proxy-server aps-filebeat sps-filebeat xps-filebeat"

default_services="cert-manager cmskv exitcodes httpgo httpsgo imagebot podmanager rucio-con-mon k8snodemon"

#cmsweb_srvs="httpgo httpsgo frontend acdcserver couchdb crabcache crabserver das dbs dqmgui phedex reqmgr2 reqmgr2-tasks reqmgr2ms reqmon t0_reqmon t0wmadatasvc workqueue workqueue-tasks exitcodes"

cmsweb_srvs="cert-manager cmskv couchdb crabserver das-exporter das-mongo das-mongo-exporter das-server dbs dbsmigration dbs2go exitcodes frontend httpgo httpsgo imagebot ms-output-mongo newdqmgui podmanager reqmgr2 reqmgr2-tasks reqmgr2ms-monitor reqmgr2ms-output reqmgr2ms-transferor reqmgr2ms-rulecleaner reqmgr2ms-unmerged reqmon reqmon-tasks rucio-con-mon t0_reqmon t0_reqmon-tasks t0wmadatasvc k8snodemon  workqueue wmarchive"

# list of DBS instances
dbs_instances="migrate  global-r global-w phys03-r phys03-w"
dbs2go_instances="global-m global-migration global-r global-w phys03-m phys03-migration phys03-r phys03-w"

# define help
if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ] || [ "$1" == "help" ] || [ "$1" == "" ]; then
    perl -ne '/^##H/ && do { s/^##H ?//; print }' < $0
    exit 1
fi
echo "+++ cmsweb environment: $CMSWEB_ENV"
echo "+++ cmsweb yaml prefix: '$prod_prefix'"
echo "+++ cmsweb env prefix : '$env_prefix'"
echo "+++ cmsweb_image_tag=  $cmsweb_image_tag"

action=$1
deployment=$2
if [ "$action" == "create" ]; then
    conf=$3
    certificates=$4
    if [ $# -eq 5 ]; then
        hmac=$5
    else
        echo "+++ generate hmac secret"
        hmac=/tmp/$USER/hmac
        perl -e 'open(R, "< /dev/urandom") or die; sysread(R, $K, 20) or die; print $K' > $hmac
    fi
    echo "+++ perform action   : $action"
    echo "+++ use configuration: $conf"
    echo "+++ use certificates : $certificates"
    echo "+++ use hmac file    : $hmac"
else
    echo "+++ perform action   : $action"
fi

# dump info about our cluster
echo "openstack --os-project-name \"$cluster_ns\" coe cluster show $cluster"
hname=`openstack --os-project-name "$cluster_ns" coe cluster show $cluster | grep node_addresses | sed -e "s,|,,g" -e "s,node_addresses,,g" -e "s, ,,g" -e "s,u,,g" -e "s,',,g" -e "s,\[,,g" -e "s,\],,g"`
echo "cmsweb cluster    : $cluster"
echo "project namespace : $cluster_ns"
echo "Kubernetes host(s): $hname"
kubectl get node

if [ "$deployment" == "services" ]; then
    # services for cmsweb cluster, adjust if necessary
    #cmsweb_ing="ing-srv"
    #cmsweb_ing="ing-couchdb ing-crab ing-dbs ing-das ing-dmwm ing-dqm ing-http ing-phedex ing-tzero ing-exitcodes"
    cmsweb_ing="ing-crab ing-dbs ing-das ing-dmwm ing-http ing-tzero ing-exitcodes ing-wma ing-dqm ing-dqm-offline"

    cmsweb_srvs="cert-manager cmskv crabserver couchdb das-exporter das-mongo das-mongo-exporter das-server dbs dbsmigration dbs2go exitcodes httpgo httpsgo imagebot ms-output-mongo newdqmgui podmanager reqmgr2 reqmgr2-tasks reqmgr2ms-monitor reqmgr2ms-output reqmgr2ms-transferor reqmgr2ms-rulecleaner reqmgr2ms-unmerged reqmon reqmon-tasks rucio-con-mon t0_reqmon t0_reqmon-tasks t0wmadatasvc k8snodemon  workqueue wmarchive"

    echo "+++ deploy services: $cmsweb_srvs"
    echo "+++ deploy ingress : $cmsweb_ing"
elif [ "$deployment" == "frontend" ]; then
    # services for cmsweb cluster
    cmsweb_ing="ing-frontend"
    cmsweb_srvs="httpgo httpsgo frontend"
    cmsweb_ns="default http"
    echo "+++ deploy services: $cmsweb_srvs"
    echo "+++ deploy ingress : $cmsweb_ing"
elif [ "$deployment" == "daemonset" ]; then
    cmsweb_ds="frontend-ds"
    echo "+++ deploy daemonset: $cmsweb_ds"
elif [ "$deployment" == "aps" ]; then
    echo "+++ deploy cmsweb auth proxy servers: $cmsweb_aps"
elif [ "$deployment" == "ingress" ]; then
    echo "+++ deploy ingress: $cmsweb_ing"
else
    echo "+++ deployment $deployment"
fi

# check status of the services
check()
{
    if [ "$deployment" != "" ]; then
        echo
        echo "*** check pods"
        kubectl get pods -n $deployment
        echo
        echo "*** check services"
        kubectl get svc -n $deployment
        echo
        echo "*** check cronjobs"
        kubectl get cronjobs -n $deployment
        echo
        echo "*** pods status"
        kubectl top pods -n $deployment
        return
    fi

    echo
    echo "*** check secrets"
    kubectl get secrets --all-namespaces
    echo
    echo "*** check ingress"
    kubectl get ing
    echo
    echo "*** check pods"
    kubectl get pods --all-namespaces
    echo
    echo "*** check services"
    kubectl get svc --all-namespaces
    echo
    echo "*** check cronjobs"
    kubectl get cronjobs --all-namespaces
    echo
    echo "*** check horizontal scalers"
    kubectl get hpa --all-namespaces
    echo
    echo "*** node status"
    kubectl top node
    echo
    echo "*** pods status"
    kubectl top pods
}

scale()
{
    if [ "$deployment" == "services" ]; then
        # dbs, generic scalers
        kubectl autoscale deployment dbsmigration --cpu-percent=80 --min=2 --max=10

        kubectl autoscale deployment dbs-migrate --cpu-percent=80 --min=2 --max=10
#        kubectl autoscale deployment dbs-global-m --cpu-percent=80 --min=2 --max=4
        kubectl autoscale deployment dbs-global-r --cpu-percent=80 --min=6 --max=12
        kubectl autoscale deployment dbs-global-w --cpu-percent=80 --min=5 --max=10
        kubectl autoscale deployment dbs-phys03-r --cpu-percent=80 --min=2 --max=4
        kubectl autoscale deployment dbs-phys03-w --cpu-percent=80 --min=2 --max=4

        #kubectl apply -f crons/cron-dbs-global-r-scaler.yaml

        # scalers for other cmsweb services
        for srv in $cmsweb_srvs; do
            # explicitly scaled above, we'll skip them here
            # we should NOT scale couchdb service since it is not transactional
            if [ "$srv" == "dbs" ] || [ "$srv" == "frontend" ] || [ "$srv" == "couchdb" ]; then
                continue
            else
                # default autoscale for service
                kubectl autoscale deployment $srv --cpu-percent=80 --min=1 --max=3
            fi
        done
    fi

    if [ "$deployment" == "frontend" ]; then
        # frontend scalers
        kubectl autoscale deployment frontend --cpu-percent=80 --min=3 --max=10
        #kubectl apply -f crons/cron-frontend-scaler.yaml
    fi

    kubectl get hpa
}

cleanup()
{
    # delete crons
    echo "--- delete crons"
    #kubectl delete -f crons
    for ns in $cmsweb_ns; do
        kubectl delete -f crons/proxy-account.yaml --namespace=$ns
        kubectl delete -f crons/scaler-account.yaml --namespace=$ns
        kubectl delete -f crons/cron-proxy.yaml --namespace=$ns
        kubectl delete -f crons/token-account.yaml --namespace=$ns
        kubectl delete -f crons/cron-token.yaml --namespace=$ns
    done

    # delete monitoring
    echo "--- delete monitoring"
    kubectl delete -f monitoring

    # delete ingress
    echo "--- delete ingress"
    for ing in $cmsweb_ing; do
        kubectl delete -f ingress/${ing}.yaml
    done

    # delete daemonset
    echo "--- delete daemonset"
    for ds in $cmsweb_ds; do
        kubectl delete -f daemonset/${ds}.yaml
    done
    for ds in $cmsweb_aps; do
        kubectl delete -f daemonset/${ds}.yaml
    done

    kubectl get nodes | grep node | awk '{print $1}' | awk '{print "kubectl label node "$1" role=ingress --overwrite"}'

    # delete secrets
    echo "--- delete secrets"
    kubectl delete secrets --all

    # delete pods
    echo "--- delete pods"
    for srv in $cmsweb_srvs; do
        # special case for DBS instances
        if [ "$srv" == "dbs" ]  ; then
            for inst in $dbs_instances; do
                if [ -f $sdir/${srv}-${inst}.yaml ]; then
                    kubectl delete -f $sdir/${srv}-${inst}.yaml
                fi
            done
        elif [ "$srv" == "dbs2go" ] ; then
            for inst in $dbs2go_instances; do
                if [ -f $sdir/${srv}-${inst}.yaml ]; then
                    kubectl delete -f $sdir/${srv}-${inst}.yaml
                fi
            done
        elif [ -f $sdir/${srv}.yaml ]; then
                kubectl delete -f $sdir/${srv}.yaml
        fi
    done

    # delete cmsweb namespaces
#    for ns in $cmsweb_ns; do
#        kubectl delete ns/$ns
#    done
#    kubectl delete ns $cmsweb_ns
    kubectl delete ns/monitoring
}

deploy_ns()
{
    # deploy all appropriate namespaces
    for ns in $cmsweb_ns; do
        if [ -z "`kubectl get namespaces | grep $ns`" ]; then
            kubectl create namespace $ns
        fi
    done
    if [ -z "`kubectl get namespaces | grep monitoring`" ]; then
        kubectl create namespace monitoring
    fi
}

deploy_secrets()
{
    # cmsweb configuration area
    echo "+++ configuration: $conf"
    echo "+++ certificates : $certificates"
    echo "+++ cms services : $cmsweb_srvs"
    echo "+++ namespaces   : $cmsweb_ns"

    # robot keys and cmsweb host certificates
    robot_key=$certificates/robotkey.pem
    robot_crt=$certificates/robotcert.pem
    cmsweb_key=$certificates/cmsweb-hostkey.pem
    cmsweb_crt=$certificates/cmsweb-hostcert.pem
    client_id=$certificates/client_id
    client_secret=$certificates/client_secret

    # check (and copy if necessary) hostkey/hostcert.pem files in configuration area of frontend
    if [ ! -f $conf/frontend/hostkey.pem ]; then
        cp $cmsweb_key $conf/frontend/hostkey.pem
    fi
    if [ ! -f $conf/frontend/hostcert.pem ]; then
        cp $cmsweb_crt $conf/frontend/hostcert.pem
    fi

    if [ ! -f $conf/frontend-ds/hostkey.pem ]; then
        cp $cmsweb_key $conf/frontend-ds/hostkey.pem
    fi
    if [ ! -f $conf/frontend-ds/hostcert.pem ]; then
        cp $cmsweb_crt $conf/frontend-ds/hostcert.pem
    fi

    if [ ! -f $conf/auth-proxy-server/tls.key ]; then
        cp $cmsweb_key $conf/auth-proxy-server/tls.key
    fi
    if [ ! -f $conf/auth-proxy-server/tls.crt ]; then
        cp $cmsweb_crt $conf/auth-proxy-server/tls.crt
    fi

    if [ ! -f $conf/x509-proxy-server/tls.key ]; then
        cp $cmsweb_key $conf/x509-proxy-server/tls.key
    fi
    if [ ! -f $conf/x509-proxy-server/tls.crt ]; then
        cp $cmsweb_crt $conf/x509-proxy-server/tls.crt
    fi
    if [ ! -f $conf/scitokens-proxy-server/tls.key ]; then
        cp $cmsweb_key $conf/scitokens-proxy-server/tls.key
    fi
    if [ ! -f $conf/scitokens-proxy-server/tls.crt ]; then
        cp $cmsweb_crt $conf/scitokens-proxy-server/tls.crt
    fi




    tls_key=/tmp/$USER/tls.key
    tls_crt=/tmp/$USER/tls.crt
    proxy=/tmp/$USER/proxy
    token=/tmp/$USER/token

    # clean-up if these files exists
    for fname in $tls_key $tls_crt $proxy $token; do
        if [ -f $fname ]; then
            rm $fname
        fi
    done

    # for ingress controller we need tls.key/tls.crt names
    cp $cmsweb_key $tls_key
    cp $cmsweb_crt $tls_crt

    # create proxy file
    voms-proxy-init -voms cms -rfc \
        --key $robot_key --cert $robot_crt --out $proxy

    # create secrets in all available namespaces
    local namespaces="$cmsweb_ns"
    for ns in $namespaces; do

    keys=$certificates/$ns-keys.txt
    echo $keys
        if [ -f $keys ]; then
            kubectl create secret generic $ns-keys-secrets \
                --from-file=$keys --dry-run=client -o yaml | \
                kubectl apply --namespace=$ns -f -
        fi

        echo "---"
        echo "Create secrets in namespace: $ns"

        # create secrets with our robot certificates
        kubectl create secret generic robot-secrets \
            --from-file=$robot_key --from-file=$robot_crt \
            --dry-run=client -o yaml | \
            kubectl apply --namespace=$ns -f -
      
        # create hmac secrets
        kubectl create secret generic hmac-secrets  --from-file=$hmac  --dry-run=client -o yaml |   kubectl apply --namespace=$ns -f -



        # create client secret
        if [ -f $client_id ] && [ -f $client_secret ]; then
            kubectl create secret generic client-secrets \
                --from-file=$client_id --from-file=$client_secret --dry-run=client -o yaml | \
                kubectl apply --namespace=$ns -f -
        fi
        if [ -f $proxy ]; then
            kubectl create secret generic proxy-secrets \
                --from-file=$proxy --dry-run=client -o yaml | \
                kubectl apply --namespace=$ns -f -
        fi

	# create token secrets
        curl -s -d grant_type=client_credentials -d scope="profile" -u ${client_id}:${client_secret} https://cms-auth.web.cern.ch/token | jq -r '.access_token' > $token

        now=$(date +'%Y%m%d %H:%M')
        if [ -f $token ]; then
            kubectl create secret generic token-secrets \
               --from-file=$token --dry-run=client -o yaml | \
               kubectl apply --namespace=$ns -f -
            echo "$now Token created."
        else
            echo "$now Failed to create token secrets"
        fi
        echo "+++ generate cmsweb service secrets"
        # create secret files for deployment, they are based on
        # - robot key (pem file)
        # - robot certificate (pem file)
        # - cmsweb hostkey (pem file)
        # - cmsweb hostcert (pem file)
        # - hmac secret file
        # - configuration files from service configuration area
        for srv in $cmsweb_srvs; do
            local secretdir=$conf/$srv
            # the underscrore is not allowed in secret names
            local osrv=$srv
            srv=`echo $srv | sed -e "s,_,,g"`
            local files=""
            secret_check="false"
### Substitution for APS/XPS/SPS client secrets in config.json	    
    if [ "$srv" == "auth-proxy-server" ] || [ "$srv" == "x509-proxy-server" ] || [ "$srv" == "scitokens-proxy-server" ] ; then
       if [ -d $secretdir ] && [ -n "`ls $secretdir`" ] && [ -f $secretdir/client.secrets ]; then
           export CLIENT_SECRET=`grep CLIENT_SECRET $secretdir/client.secrets | head -n1 | awk '{print $2}'`
           export CLIENT_ID=`grep CLIENT_ID $secretdir/client.secrets | head -n1 | awk '{print $2}'`
           export IAM_CLIENT_ID=`grep IAM_CLIENT_ID $secretdir/client.secrets | head -n1 | awk '{print $2}'`
           export IAM_CLIENT_SECRET=`grep IAM_CLIENT_SECRET $secretdir/client.secrets | head -n1 | awk '{print $2}'`
           export COUCHDB_USER=`grep COUCHDB_USER $secretdir/client.secrets | head -n1 | awk '{print $2}'`
           export COUCHDB_PASSWORD=`grep COUCHDB_PASSWORD $secretdir/client.secrets | head -n1 | awk '{print $2}'`
           if [ -f $secretdir/config.json ]; then
              if [ -n "${IAM_CLIENT_ID}" ]; then
                 sed -i -e "s,IAM_CLIENT_ID,$IAM_CLIENT_ID,g" $secretdir/config.json
              fi
              if [ -n "${IAM_CLIENT_SECRET}" ]; then
                 sed -i -e "s,IAM_CLIENT_SECRET,$IAM_CLIENT_SECRET,g" $secretdir/config.json
              fi
              if [ -n "${CLIENT_ID}" ]; then
                 sed -i -e "s,CLIENT_ID,$CLIENT_ID,g" $secretdir/config.json
              fi
              if [ -n "${CLIENT_SECRET}" ]; then
                 sed -i -e "s,CLIENT_SECRET,$CLIENT_SECRET,g" $secretdir/config.json
              fi
              if [ -n "${COUCHDB_USER}" ]; then
                 sed -i -e "s,COUCHDB_USER,$COUCHDB_USER,g" $secretdir/config.json
              fi
              if [ -n "${COUCHDB_PASSWORD}" ]; then
                 sed -i -e "s,COUCHDB_PASSWORD,$COUCHDB_PASSWORD,g" $secretdir/config.json
              fi
          fi
       fi
    fi

            if [ -d $secretdir ] && [ -n "`ls $secretdir`" ]; then
                for fname in $secretdir/*; do
                    files="$files --from-file=$fname"
                done
            fi
            # special case for DBS instances
            if [ "$srv" == "dbs" ] ; then
                secret_check="true"
                if [ -f $conf/dbs/DBSSecrets.py ]; then
   		             files="--from-file=$conf/dbs/DBSSecrets.py"
                fi
                if [ -f $conf/dbs/NATSSecrets.py ]; then
                        files="$files --from-file=$conf/dbs/NATSSecrets.py"
                fi
                for inst in $dbs_instances; do
                    local dbsfiles=""
                    if [ -d "$secretdir-$inst" ] && [ -n "`ls $secretdir-$inst`" ]; then
                        for fconf in $secretdir-$inst/*; do
                            dbsfiles="$dbsfiles --from-file=$fconf"
                        done

                    fi
                    # proceed only if service namespace matches the loop one
                    local srv_ns=`grep namespace $sdir/${osrv}-${inst}.yaml | grep $ns`
                    if [ -z "$srv_ns" ] ; then
                        continue
                    fi
                    kubectl create secret generic ${srv}-${inst}-secrets \
                        $files $dbsfiles --dry-run=client -o yaml | \
                        kubectl apply --namespace=$ns -f -
                done
                # Deleting configmap for tnsnames in dbs namespace
                kubectl delete cm tnsnames-config --namespace=$ns
                # Creating configmap for tnsnames in dbs namespace
                kubectl create cm tnsnames-config \
                    --from-file=$conf/tnsnames/tnsnames.ora --dry-run=client -o yaml | \
                    kubectl apply --namespace=$ns -f -
            fi

            if [ "$srv" == "dbs2go" ]; then
                secret_check="true"
                for inst in $dbs2go_instances; do
                    local dbsfiles=""
                    if [ -d "$secretdir-$inst" ] && [ -n "`ls $secretdir-$inst`" ]; then
                        for fconf in $secretdir-$inst/*; do
                            dbsfiles="$dbsfiles --from-file=$fconf"
                        done

                    fi
                    # proceed only if service namespace matches the loop one
                    local srv_ns=`grep namespace $sdir/${osrv}-${inst}.yaml | grep $ns`
                    if [ -z "$srv_ns" ] ; then
                        continue
                    fi
                    kubectl create secret generic ${srv}-${inst}-secrets \
                        $dbsfiles --dry-run=client -o yaml | \
                        kubectl apply --namespace=$ns -f -
                done
                # Deleting configmap for tnsnames in dbs namespace
                kubectl delete cm tnsnames-config --namespace=$ns
                # Creating configmap for tnsnames in dbs namespace
                kubectl create cm tnsnames-config \
                    --from-file=$conf/tnsnames/tnsnames.ora --dry-run=client -o yaml | \
                    kubectl apply --namespace=$ns -f -
            fi
            
            local srv_ns=`grep namespace $sdir/${osrv}.yaml | grep $ns`
            if [ -z "$srv_ns" ] ; then
               continue
            fi
            if [ "$secret_check" == "false" ]; then
                kubectl create secret generic ${srv}-secrets \
                $files --dry-run=client -o yaml | \
                kubectl apply --namespace=$ns -f -

            fi
        done

        for srv in $cmsweb_ds; do
            local secretdir=$conf/$srv
            # the underscrore is not allowed in secret names
            local osrv=$srv
            srv=`echo $srv | sed -e "s,_,,g"`
            local files=""
            if [ -d $secretdir ] && [ -n "`ls $secretdir`" ]; then
                for fname in $secretdir/*; do
                    files="$files --from-file=$fname"
                done
            fi
            local srv_ns=`grep namespace $ddir/${osrv}.yaml | grep $ns`
                if [ -z "$srv_ns" ] ; then
                    continue
                fi
                kubectl create secret generic ${srv}-secrets \
                    $files --dry-run=client -o yaml | \
                    kubectl apply --namespace=$ns -f -
        done
        for srv in $cmsweb_aps; do
            local secretdir=$conf/$srv
            # the underscrore is not allowed in secret names
            local osrv=$srv
            srv=`echo $srv | sed -e "s,_,,g"`
            local files=""
            if [ -d $secretdir ] && [ -n "`ls $secretdir`" ]; then
                for fname in $secretdir/*; do
                    files="$files --from-file=$fname"
                done
            fi
            local srv_ns=`grep namespace $ddir/${osrv}.yaml | grep $ns`
                if [ -z "$srv_ns" ] ; then
                    continue
                fi
                kubectl create secret generic ${srv}-secrets \
                    $files --dry-run=client -o yaml | \
                    kubectl apply --namespace=$ns -f -
        done
    done

    # create ingress secrets file, it requires tls.key/tls.crt files

    kubectl create secret generic ing-secrets \
        --from-file=$tls_key --from-file=$tls_crt --dry-run=client -o yaml | \
        kubectl apply -f -

    # perform clean-up
    if [ -f $tls_key ]; then
        rm $tls_key
    fi
    if [ -f $tls_crt ]; then
        rm $tls_crt
    fi
    if [ -f $proxy ]; then
        rm $proxy
    fi

    # use one of the option below
    # generate tls.key/tls.crt for custom CA and openssl config
#    echo "+++ create secrets for TLS case"
#    openssl genrsa -out tls.key 3072 -config openssl.cnf; openssl req -new -x509 -key tls.key -sha256 -out tls.crt -days 730 -config openssl.cnf -subj "/CN=cmsweb-test.web.cern.ch"

    # generate tls.key/tls.crt without openssl config
    #openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=cmsweb-test.web.cern.ch"

    # create secret with our tls.key/tls.crt
#    kubectl create secret tls cluster-tls-cert --key=tls.key --cert=tls.crt

    # create secret with our key/crt (they can be generated at ca.cern.ch/ca, see Host certificates)
    # we need to use this option if ing-frontend.yaml will contain the following configuration
    # tls:
    #    - secretName: cluster-tls-cert
    echo
    echo "+++ create cluster tls secret from key=$cmsweb_key, cert=$cmsweb_crt"
    kubectl create secret tls cluster-tls-cert --key=$cmsweb_key --cert=$cmsweb_crt

    echo
    echo "+++ list sercres and configmap"
    kubectl get secrets --all-namespaces
    #kubectl -n kube-system get secrets

}

deploy_monitoring()
{
    echo
    echo "+++ create monitoring namespace"
    if [ -z "`kubectl get namespaces | grep monitoring`" ]; then
        kubectl create namespace monitoring
    fi

    cat monitoring/kube-eagle.yaml | sed -e "s,k8s #k8s#,$env_prefix,g" | kubectl apply -f -


    echo
    echo "+++ deploy monitoring services"
    # add kube-eagle
    #if [ "$CMSWEB_ENV" == "production" ] || [ "$CMSWEB_ENV" == "prod" ]; then
    #    cat monitoring/kube-eagle.yaml | sed -e 's,k8s #k8s#,"k8s-prod",g' | kubectl apply -f -
    #elif [ "$CMSWEB_ENV" == "preproduction" ] || [ "$CMSWEB_ENV" == "preprod" ]; then
    #    cat monitoring/kube-eagle.yaml | sed -e 's,k8s #k8s#,"k8s-preprod",g' | kubectl apply -f -
    #else
    #    kubectl apply -f monitoring/kube-eagle.yaml
    #fi

    # use common logstash yaml for ALL services
    #kubectl -n monitoring apply -f monitoring/logstash.yaml
    cat monitoring/logstash.yaml | \
        sed -e "s,dev # cmsweb_env,$env_prefix,g" | \
        sed -e "s,dev # cluster,$cluster,g" | \
        kubectl -n monitoring apply -f -
    # CRAB logstash
    cat monitoring/crab/logstash.yaml | \
        sed -e "s,dev # cmsweb_env,$env_prefix,g" | \
        sed -e "s,dev # cluster,$cluster,g" | \
        kubectl -n crab apply -f -
    # if we need to split monitoring by services
    #if [ "$deployment" == "frontend" ]; then
    #    kubectl -n monitoring apply -f monitoring/logstash-frontend.yaml
    #fi
    #if [ "$deployment" == "services" ]; then
    #    for ns in $cmsweb_ns; do
    #        if [ -f monitoring/logstash-${ns}.yaml ]; then
    #            kubectl -n $ns apply -f monitoring/logstash-${ns}.yaml
    #        fi
    #    done
    #fi

    # locate all prometheus files
    local mon=""
    if [ "$deployment" == "services" ] || [ "$deployment" == "aps" ]; then
        mon="services"
    else
        mon="frontend"
    fi
    local files=""
    if [ -d monitoring ] && [ -n "`ls monitoring/prometheus/$mon`" ]; then
        # change "k8s" env label in prometheus.yaml files based on our cmsweb environment
        if [ -f monitoring/prometheus/$mon/prometheus.yaml ]; then

            cat monitoring/prometheus/$mon/prometheus.yaml | sed -e 's,"k8s",$env_prefix,g' > /tmp/prometheus.yaml

##            if [ "$CMSWEB_ENV" == "production" ] || [ "$CMSWEB_ENV" == "prod" ]; then
##                cat monitoring/prometheus/$mon/prometheus.yaml | sed -e 's,"k8s","k8s-prod",g' > /tmp/prometheus.yaml
##            fi
##            if [ "$CMSWEB_ENV" == "preproduction" ] || [ "$CMSWEB_ENV" == "preprod" ]; then
##                cat monitoring/prometheus/$mon/prometheus.yaml | sed -e 's,"k8s","k8s-preprod",g' > /tmp/prometheus.yaml
##            fi
        fi
        if [ -f /tmp/prometheus.yaml ]; then
            files="$files --from-file=/tmp/prometheus.yaml"
        else
            files="$files --from-file=monitoring/prometheus/$mon/prometheus.yaml"
        fi
        for fname in monitoring/prometheus/rules/*; do
            files="$files --from-file=$fname"
        done
    fi
    kubectl create secret generic prometheus-secrets \
        $files --dry-run=client -o yaml | \
        kubectl apply --namespace=monitoring -f -

    # add config map for prometheus adapter
    if [ -n "`kubectl get cm -n monitoring | grep prometheus-adapter-configmap`" ]; then
        kubectl delete configmap prometheus-adapter-configmap -n monitoring
    fi
    kubectl create configmap prometheus-adapter-configmap \
        --from-file=monitoring/prometheus/adapter/prometheus_adapter.yml -n monitoring

    # add config map for logstash
    if [ -n "`kubectl get cm -n monitoring | grep logstash`" ]; then
        kubectl delete configmap logstash -n monitoring
    fi
    # add config map for logstash -n crab
    if [ -n "`kubectl get cm -n crab | grep logstash`" ]; then
        kubectl delete configmap logstash -n crab
    fi

    if [ "$deployment" == "aps" ]; then
        kubectl create configmap logstash \
        --from-file=monitoring/aps/logstash.conf --from-file=monitoring/logstash.yml -n monitoring
    else
    # create monitoring logstash config map
    kubectl create configmap logstash \
        --from-file=monitoring/logstash.conf --from-file=monitoring/logstash.yml -n monitoring
    # creat crab logstash config map
    kubectl create configmap logstash \
        --from-file=monitoring/crab/logstash.conf --from-file=monitoring/crab/logstash.yml -n crab

    fi
    # add secrets for loki service
    if [ -n "`kubectl get secrets -n monitoring | grep loki-secrets`" ]; then
        kubectl delete secrets loki-secrets -n monitoring
    fi
    kubectl create secret generic loki-secrets \
        --from-file=monitoring/loki-config.yaml --dry-run=client -o yaml | \
        kubectl apply --namespace=monitoring -f -
    kubectl apply --namespace=monitoring -f monitoring/loki.yaml

    kubectl -n monitoring apply -f monitoring/prometheus.yaml
    kubectl -n monitoring apply -f monitoring/prometheus-adapter.yaml
    kubectl -n monitoring get deployments
    kubectl -n monitoring get pods
    prom=`kubectl -n monitoring get pods | grep prom | awk '{print $1}'`
    echo "### we may access prometheus locally as following"
    echo "kubectl -n monitoring port-forward $prom 8080:9090"
    echo "### to access prometheus externally we should do the following:"
    echo "ssh -S none -L 30000:kubehost:30000 $USER@lxplus.cern.ch"
}

deploy_storages()
{
    echo "+++ label node for PVC storage access"
    for n in `kubectl get nodes | grep -v master | grep -v NAME | awk '{print $1}'`; do
        kubectl label node $n failure-domain.beta.kubernetes.io/zone=nova --overwrite
        kubectl label node $n failure-domain.beta.kubernetes.io/region=cern --overwrite
    done
    #Deploy storage for testbed cluster
    if [[ "$CMSWEB_ENV" == "preproduction"  ||  "$CMSWEB_ENV" == "preprod" ]]; then
       kubectl apply -f storages/cephfs-storage-logs-preprod-ds-v1.22.yaml
       kubectl apply -f storages/cephfs-storage-dqm-preprod-v1.22.yaml
       kubectl apply -f storages/dqm-cvmfs.yaml
       kubectl apply -f storages/cephfs-storage-filebeat-v1.22.yaml
       kubectl apply -f storages/cephfs-storage-filebeatcrab-v1.22.yaml
       kubectl apply -f storages/cephfs-storage-msoutput-preprod-v1.22.yaml
       kubectl apply -f storages/cephfs-storage-ruciocm-ds-v1.22.yaml
    fi
    # Deploy storage for production cluster
    if [[ "$CMSWEB_ENV" == "production"  ||  "$CMSWEB_ENV" == "prod" ]]; then
       if [[ "$cmsweb_hostname" == "cmsweb.cern.ch" ]]; then
          kubectl apply -f storages/cephfs-storage-cmsweb-v1.22.yaml
          kubectl apply -f storages/cephfs-storage-filebeat-v1.22.yaml	  
       elif [[ "$cmsweb_hostname" == "cmsweb-prod.cern.ch" ]]; then
          kubectl apply -f storages/cephfs-storage-cmsweb-prod-v1.22.yaml
          kubectl apply -f storages/cephfs-storage-filebeat-v1.22.yaml
       else
          kubectl apply -f storages/cephfs-storage-logs-prod-ds-v1.22.yaml
          kubectl apply -f storages/cephfs-storage-dqm-prod-v1.22.yaml
          kubectl apply -f storages/dqm-cvmfs.yaml
          kubectl apply -f storages/cephfs-storage-filebeatcrab-v1.22.yaml
          kubectl apply -f storages/cephfs-storage-msoutput-prod-v1.22.yaml
          kubectl apply -f storages/cephfs-storage-ruciocm-ds-v1.22.yaml
       fi
    fi

}

# deploy cluster roles
deploy_roles()
{
    kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
}

# deploy appripriate daemonset for our cluster
deploy_daemonset()
{

    for n in `kubectl get nodes | grep -v master | grep -v NAME | awk '{print $1}'`; do
        kubectl label node $n role=auth --overwrite
        kubectl get node -l role=auth
    done
    if [[ "$CMSWEB_ENV" == "production"  ||  "$CMSWEB_ENV" == "prod"  ||  "$CMSWEB_ENV" == "preproduction"  ||  "$CMSWEB_ENV" == "preprod" ]] ; then
    
    for ds in $cmsweb_ds; do

           cat daemonset/${ds}.yaml | \
           sed -e "s,#PROD#,$prod_prefix,g" | \
           sed -e "s,k8s #k8s#,$env_prefix,g" | \
           sed -e "s,logs-cephfs-claim,logs-cephfs-claim$logs_prefix,g" | \
           sed -e "s, #imagetag,$cmsweb_image_tag,g" | \
           kubectl apply -f -

    done
    
    else

   for ds in $cmsweb_ds; do

           cat daemonset/${ds}.yaml | \
           sed -e "s,k8s #k8s#,$env_prefix,g" | \
           sed -e "s, #imagetag,$cmsweb_image_tag,g" | \
           kubectl apply -f -
    done
    fi
}

deploy_aps()
{
    for n in `kubectl get nodes | grep -v master | grep -v NAME | awk '{print $1}'`; do
        kubectl label node $n role=auth --overwrite
        kubectl get node -l role=auth
    done
    if [[ "$CMSWEB_ENV" == "production"  ||  "$CMSWEB_ENV" == "prod"  ||  "$CMSWEB_ENV" == "preproduction"  ||  "$CMSWEB_ENV" == "preprod" ]] ; then

    for ds in $cmsweb_aps; do

           cat daemonset/${ds}.yaml | \
           sed -e "s,#PROD#,$prod_prefix,g" | \
           sed -e "s,k8s #k8s#,$env_prefix,g" | \
           sed -e "s,logs-cephfs-claim,logs-cephfs-claim$logs_prefix,g" | \
           sed -e "s, #imagetag,$cmsweb_image_tag,g" | \
           kubectl apply -f -

    done

    else

   for ds in $cmsweb_aps; do

           cat daemonset/${ds}.yaml | \
           sed -e "s, #imagetag,$cmsweb_image_tag,g" | \
           sed -e "s,k8s #k8s#,$env_prefix,g" | \
           kubectl apply -f -
    done
    fi
}

# deploy appripriate ingress controller for our cluster
deploy_ingress()
{
#    echo
#    echo "+++ list configmap"
#    kubectl -n kube-system get configmap

    echo
    echo "+++ label node"
    for n in `kubectl get nodes | grep -v master | grep -v NAME | awk '{print $1}'`; do
        kubectl label node $n role=ingress --overwrite
        kubectl get node -l role=ingress
    done

    echo
    echo "+++ deploy $cmsweb_ing"
    echo "+++ use CMSWEB_HOSTNAME=$cmsweb_hostname"
    ips=`host $cmsweb_hostname_frontend | awk '{ORS=","; print $4}' | rev | cut -c2- | rev`
    ips_cmsweb=`host cmsweb-prod.cern.ch | awk '{ORS=","; print $4}' | rev | cut -c2- | rev`
    
    ips=$ips,$ips_cmsweb

    echo "+++ use CMSWEB IPs: $ips"
    tmpDir=/tmp/$USER/ingress
    mkdir -p $tmpDir
    for ing in $cmsweb_ing; do
        cp ingress/${ing}.yaml $tmpDir
        if [[ "$CMSWEB_ENV" == "production" || "$CMSWEB_ENV" == "prod" ]] && [[ "$ing" == "ing-dbs"  ]] ; then
                cat ingress/${ing}.yaml | \
                awk '{if($1=="nginx.ingress.kubernetes.io/whitelist-source-range:") {print "    nginx.ingress.kubernetes.io/whitelist-source-range: "ips""} else print $0}' ips=$ips | \
                awk '{if($2=="host:") {print "  - host : "hostname""} else print $0}' hostname=$cmsweb_hostname | \
                awk '{if($2=="cmsweb-test.cern.ch") {print "    - "hostname""} else print $0}' hostname=$cmsweb_hostname | \
                sed -e "s,dbs/int,dbs/prod,g"  \
                > $tmpDir/${ing}.yaml
        else
                cat ingress/${ing}.yaml | \
                awk '{if($1=="nginx.ingress.kubernetes.io/whitelist-source-range:") {print "    nginx.ingress.kubernetes.io/whitelist-source-range: "ips""} else print $0}' ips=$ips | \
                awk '{if($2=="host:") {print "  - host : "hostname""} else print $0}' hostname=$cmsweb_hostname | \
                awk '{if($2=="cmsweb-test.cern.ch") {print "    - "hostname""} else print $0}' hostname=$cmsweb_hostname \
                > $tmpDir/${ing}.yaml
        fi
        echo "deploy ingress: $tmpDir/${ing}.yaml"
        cat $tmpDir/${ing}.yaml
        kubectl apply -f $tmpDir/${ing}.yaml
        #kubectl apply -f ingress/${ing}.yaml
    done
    rm -rf $tmpDir
}
deploy_crons()
{
    echo
    echo "+++ deploy crons"
    # we'll use explicit name of crons, here a common list
    # for both clusters
    for ns in $cmsweb_ns; do
        kubectl apply -f crons/proxy-account.yaml --namespace=$ns
        kubectl apply -f crons/scaler-account.yaml --namespace=$ns
        kubectl apply -f crons/cron-proxy.yaml --namespace=$ns
        kubectl apply -f crons/token-account.yaml --namespace=$ns
        kubectl apply -f crons/cron-token.yaml --namespace=$ns
    done
}

deploy_default_services()
{
    echo
    echo "+++ deploy services: $default_services"
    for srv in $default_services; do
         if [ -f $sdir/${srv}.yaml ]; then
                if [[ "$CMSWEB_ENV" == "production"  ||  "$CMSWEB_ENV" == "prod"  ||  "$CMSWEB_ENV" == "preproduction"  ||  "$CMSWEB_ENV" == "preprod" ]] ; then
                        cat $sdir/${srv}.yaml | \
                        sed -e "s,replicas: 1 #PROD#,replicas: ,g" | \
                        sed -e "s,replicas: 2 #PROD#,replicas: ,g" | \
                        sed -e "s,#PROD#,$prod_prefix,g" | \
                        sed -e "s,k8s #k8s#,$env_prefix,g" | \
                        sed -e "s,logs-cephfs-claim,logs-cephfs-claim$logs_prefix,g" | \
                        sed -e "s, #imagetag,$cmsweb_image_tag,g" | \
                        kubectl apply -f -
                else
                        sed -e "s,k8s #k8s#,$env_prefix,g" | \
                        kubectl apply -f $sdir/${srv}.yaml
                fi
         fi
    done
}


deploy_services()
{
    echo
    echo "+++ deploy services: $cmsweb_srvs"
    for srv in $cmsweb_srvs; do
        if [ "$srv" == "dbs" ] ; then
            for inst in $dbs_instances; do
                if [ -f "$sdir/${srv}-${inst}.yaml" ]; then
                    #kubectl apply -f "$sdir/${srv}-${inst}.yaml"
                      if [[ "$CMSWEB_ENV" == "production"  ||  "$CMSWEB_ENV" == "prod"  ||  "$CMSWEB_ENV" == "preproduction"  ||  "$CMSWEB_ENV" == "preprod" ]] ; then
                            cat $sdir/${srv}-${inst}.yaml | \
                            sed -e "s,replicas: 1 #PROD#,replicas: ,g" | \
                            sed -e "s,#PROD#,$prod_prefix,g" | \
                            sed -e "s,k8s #k8s#,$env_prefix,g" | \
                            sed -e "s,logs-cephfs-claim,logs-cephfs-claim$logs_prefix,g" | \
                            sed -e "s, #imagetag,$cmsweb_image_tag,g" | \
                            kubectl apply -f -
                      else
                            sed -e "s,k8s #k8s#,$env_prefix,g" | \
	                    kubectl apply -f $sdir/${srv}-${inst}.yaml
                      fi
                fi
            done
        elif [ "$srv" == "dbs2go" ] ; then
            for inst in $dbs2go_instances; do
                if [ -f "$sdir/${srv}-${inst}.yaml" ]; then
                    #kubectl apply -f "$sdir/${srv}-${inst}.yaml"
                      if [[ "$CMSWEB_ENV" == "production"  ||  "$CMSWEB_ENV" == "prod"  ||  "$CMSWEB_ENV" == "preproduction"  ||  "$CMSWEB_ENV" == "preprod" ]] ; then
                            cat $sdir/${srv}-${inst}.yaml | \
                            sed -e "s,replicas: 1 #PROD#,replicas: ,g" | \
                            sed -e "s,#PROD#,$prod_prefix,g" | \
                            sed -e "s,k8s #k8s#,$env_prefix,g" | \
                            sed -e "s,logs-cephfs-claim,logs-cephfs-claim$logs_prefix,g" | \
                            sed -e "s, #imagetag,$cmsweb_image_tag,g" | \
                            kubectl apply -f -
                      else
                            sed -e "s,k8s #k8s#,$env_prefix,g" | \
                      kubectl apply -f $sdir/${srv}-${inst}.yaml
                      fi
                fi
            done
        elif [ -f $sdir/${srv}.yaml ]; then
                #kubectl apply -f $sdir/${srv}.yaml 
                if [[ "$CMSWEB_ENV" == "production"  ||  "$CMSWEB_ENV" == "prod"  ||  "$CMSWEB_ENV" == "preproduction"  ||  "$CMSWEB_ENV" == "preprod" ]] ; then
                        cat $sdir/${srv}.yaml | \
                        sed -e "s,replicas: 1 #PROD#,replicas: ,g" | \
                        sed -e "s,replicas: 2 #PROD#,replicas: ,g" | \
                        sed -e "s,#PROD#,$prod_prefix,g" | \
                        sed -e "s,k8s #k8s#,$env_prefix,g" | \
                        sed -e "s,logs-cephfs-claim,logs-cephfs-claim$logs_prefix,g" | \
                        sed -e "s, #imagetag,$cmsweb_image_tag,g" | \
                        kubectl apply -f -
                else
                        sed -e "s,k8s #k8s#,$env_prefix,g" | \
                        kubectl apply -f $sdir/${srv}.yaml
                fi
        fi
    done
}

create()
{
    local project=${OS_PROJECT_NAME:-"CMS Web"}
    local cluster=${CMSWEB_CLUSTER:-cmsweb}
    local template=${CMSWEB_TMPL:-"cmsweb-template-stable"}
    local keypair=${CMSWEB_KEY:-"cloud"}
    if [ "$deployment" == "cluster" ]; then
        echo
        openstack --os-project-name "$project" coe cluster template list
        openstack --os-project-name "$project" coe cluster create --keypair $keypair --cluster-template $template $cluster
        openstack --os-project-name "$project" coe cluster list
    elif [ "$deployment" == "secrets" ]; then
        deploy_ns
      	deploy_crons
        deploy_roles
        deploy_secrets
    elif [ "$deployment" == "ingress" ]; then
        deploy_ingress
    elif [ "$deployment" == "daemonset" ]; then
        deploy_daemonset
    elif [ "$deployment" == "aps" ]; then
        deploy_aps
    elif [ "$deployment" == "monitoring_backend" ]; then
        deployment=services
        deploy_monitoring
    elif [ "$deployment" == "monitoring_frontend" ]; then
        deployment=frontend
        deploy_monitoring
    elif [ "$deployment" == "monitoring_aps" ]; then
        deployment=aps
        deploy_monitoring
    elif [ "$deployment" == "storages" ]; then
        deploy_storages
    elif [ "$deployment" == "default_services" ]; then 
        deploy_default_services
    else
        deploy_ns
        deploy_secrets
        if [[ ("$CMSWEB_ENV" == "production"  ||  "$CMSWEB_ENV" == "prod"  ||  "$CMSWEB_ENV" == "preproduction"  ||  "$CMSWEB_ENV" == "preprod")  && ("$deployment" == "services") ]]; then
             deploy_storages
        fi
        deploy_services
        deploy_roles
        if [ "$SERVICES_INGRESS" == "yes" ]; then
             deploy_ingress
        fi
        deploy_crons
        deploy_monitoring
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

  secrets )
    deploy_secrets
    ;;

  status )
    check
    ;;

  scale )
    scale
    ;;

  help )
    perl -ne '/^##H/ && do { s/^##H ?//; print }' < $0
    ;;

  * )
    perl -ne '/^##H/ && do { s/^##H ?//; print }' < $0
    ;;
esac
