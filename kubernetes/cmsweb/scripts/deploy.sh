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
##H   frontend   deploy frontend cluster
##H   ingress    deploy ingress controller
##H   monitoring deploy monitoring components
##H   crons      deploy crons components
##H   secrets    create secrets files
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
cmsweb_hostname=${CMSWEB_HOSTNAME:-cmsweb-test.cern.ch}
cmsweb_hostname_frontend=${CMSWEB_HOSTNAME_FRONTEND:-cmsweb-test.cern.ch}
prod_prefix="#PROD#"
if [ "$CMSWEB_ENV" == "production" ] || [ "$CMSWEB_ENV" == "prod" ]; then
    prod_prefix="      " # will replace '#PROD#' prefix
fi
# we define preprod_prefix as empty for all use-cases
preprod_prefix=""
# we'll use specific preprod_prefix on preproduction deployment
# this will be used for cephfs shares
if [ "$CMSWEB_ENV" == "preproduction" ] || [ "$CMSWEB_ENV" == "preprod" ]; then
    prod_prefix="      " # will replace '#PROD#' prefix
    preprod_prefix="-preprod" # will replace logs-cephfs-claim with this prefix
fi
sdir=services
mdir=monitoring
idir=ingress
cdir=crons

# cmsweb service namespaces
cmsweb_ns=`grep namespace $sdir/* | awk '{print $3}' | sort | uniq`

# services for cmsweb cluster, adjust if necessary
#cmsweb_ing="ing-srv"
cmsweb_ing="ing-confdb ing-couchdb ing-crab ing-dbs ing-das ing-dmwm ing-dqm ing-http ing-phedex ing-tfaas ing-tzero"
cmsweb_srvs="httpgo httpsgo frontend acdcserver alertscollector confdb couchdb crabcache crabserver das dbs dqmgui phedex reqmgr2 reqmgr2-tasks reqmgr2ms reqmon t0_reqmon t0wmadatasvc workqueue workqueue-tasks"

# list of DBS instances
dbs_instances="migrate  global-r global-w phys03-r phys03-w"

# define help
if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ] || [ "$1" == "help" ] || [ "$1" == "" ]; then
    perl -ne '/^##H/ && do { s/^##H ?//; print }' < $0
    exit 1
fi
echo "+++ cmsweb environment: $CMSWEB_ENV"
echo "+++ cmsweb yaml prefix: '$prod_prefix'"
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
    cmsweb_ing="ing-confdb ing-couchdb ing-crab ing-dbs ing-das ing-dmwm ing-dqm ing-http ing-phedex ing-tfaas ing-tzero"
    cmsweb_srvs="httpgo httpsgo acdcserver alertscollector confdb couchdb crabcache crabserver das dbs dqmgui phedex reqmgr2 reqmgr2-tasks reqmgr2ms reqmon t0_reqmon t0wmadatasvc workqueue workqueue-tasks"
    echo "+++ deploy services: $cmsweb_srvs"
    echo "+++ deploy ingress : $cmsweb_ing"
elif [ "$deployment" == "frontend" ]; then
    # services for cmsweb cluster
    cmsweb_ing="ing-frontend"
    cmsweb_srvs="httpgo httpsgo frontend"
    echo "+++ deploy services: $cmsweb_srvs"
    echo "+++ deploy ingress : $cmsweb_ing"
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
        kubectl autoscale deployment dbs-migrate --cpu-percent=80 --min=2 --max=10
#        kubectl autoscale deployment dbs-global-m --cpu-percent=80 --min=2 --max=4
        kubectl autoscale deployment dbs-global-r --cpu-percent=80 --min=6 --max=12
        kubectl autoscale deployment dbs-global-w --cpu-percent=80 --min=5 --max=10
        kubectl autoscale deployment dbs-phys03-r --cpu-percent=80 --min=2 --max=4
        kubectl autoscale deployment dbs-phys03-w --cpu-percent=80 --min=2 --max=4

        #kubectl apply -f crons/cron-dbs-global-r-scaler.yaml --validate=false

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
        #kubectl apply -f crons/cron-frontend-scaler.yaml --validate=false
    fi

    kubectl get hpa
}

cleanup()
{
    # delete crons
    echo "--- delete crons"
    #kubectl delete -f crons
    for ns in $cmsweb_ns; do
        kubectl apply -f crons/proxy-account.yaml --namespace=$ns
        kubectl apply -f crons/scaler-account.yaml --namespace=$ns
        kubectl apply -f crons/cron-proxy.yaml --namespace=$ns
    done

    # delete monitoring
    echo "--- delete monitoring"
    kubectl delete -f monitoring

    # delete ingress
    echo "--- delete ingress"
    for ing in $cmsweb_ing; do
        kubectl delete -f ingress/${ing}.yaml
    done

    # delete secrets
    echo "--- delete secrets"
    kubectl delete secrets --all

    # delete pods
    echo "--- delete pods"
    for srv in $cmsweb_srvs; do
        # special case for DBS instances
        if [ "$srv" == "dbs" ]; then
            for inst in $dbs_instances; do
                if [ -f $sdir/${srv}-${inst}.yaml ]; then
                    kubectl delete -f $sdir/${srv}-${inst}.yaml
                fi
            done
        else
            if [ -f $sdir/${srv}.yaml ]; then
                kubectl delete -f $sdir/${srv}.yaml
            fi
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

    # check (and copy if necessary) hostkey/hostcert.pem files in configuration area of frontend
    if [ ! -f $conf/frontend/hostkey.pem ]; then
        cp $cmsweb_key $conf/frontend/hostkey.pem
    fi
    if [ ! -f $conf/frontend/hostcert.pem ]; then
        cp $cmsweb_crt $conf/frontend/hostcert.pem
    fi

    tls_key=/tmp/$USER/tls.key
    tls_crt=/tmp/$USER/tls.crt
    proxy=/tmp/$USER/proxy

    # clean-up if these files exists
    for fname in $tls_key $tls_crt $proxy; do
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
    local namespaces="default $cmsweb_ns"
    for ns in $namespaces; do
        echo "---"
        echo "Create secrets in namespace: $ns"

        # create secrets with our robot certificates
        kubectl create secret generic robot-secrets \
            --from-file=$robot_key --from-file=$robot_crt \
            $files --dry-run -o yaml | \
            kubectl apply --namespace=$ns --validate=false -f -

        # create proxy secret
        if [ -f $proxy ]; then
            kubectl create secret generic proxy-secrets \
                --from-file=$proxy --dry-run -o yaml | \
                kubectl apply --namespace=$ns --validate=false -f -
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
            if [ -d $secretdir ] && [ -n "`ls $secretdir`" ]; then
                for fname in $secretdir/*; do
                    files="$files --from-file=$fname"
                done
            fi
            # special case for DBS instances
            if [ "$srv" == "dbs" ]; then
                files="--from-file=$conf/dbs/DBSSecrets.py"
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
                        --from-file=$robot_key --from-file=$robot_crt \
                        --from-file=$hmac \
                        $files $dbsfiles --dry-run -o yaml | \
                        kubectl apply --namespace=$ns --validate=false -f -
                done
            else
                # proceed only if service namespace matches the loop one
                local srv_ns=`grep namespace $sdir/${osrv}.yaml | grep $ns`
                if [ -z "$srv_ns" ] ; then
                    continue
                fi
                kubectl create secret generic ${srv}-secrets \
                    --from-file=$robot_key --from-file=$robot_crt \
                    --from-file=$hmac \
                    $files --dry-run -o yaml | \
                    kubectl apply --namespace=$ns --validate=false -f -
            fi
        done

    done

    # create ingress secrets file, it requires tls.key/tls.crt files
    kubectl create secret generic ing-secrets \
        --from-file=$tls_key --from-file=$tls_crt --dry-run -o yaml | \
        kubectl apply --validate=false -f -

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

    echo
    echo "+++ deploy monitoring services"
    # use common logstash yaml for ALL services
    kubectl -n monitoring apply -f monitoring/logstash.yaml
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
    if [ "$deployment" == "services" ]; then
        kubectl -n monitoring apply -f monitoring/prometheus-services.yaml
    elif [ "$deployment" == "frontend" ]; then
        kubectl -n monitoring apply -f monitoring/prometheus-frontend.yaml
    fi
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
    kubectl apply -f storages/cinder-storage.yaml
}

# deploy cluster roles
deploy_roles()
{
    kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
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
    echo "+++ use CMSWEB IPs: $ips"
    tmpDir=/tmp/$USER/ingress
    mkdir -p $tmpDir
    for ing in $cmsweb_ing; do
        cp ingress/${ing}.yaml $tmpDir
	cat ingress/${ing}.yaml | \
    	awk '{if($1=="nginx.ingress.kubernetes.io/whitelist-source-range:") {print "    nginx.ingress.kubernetes.io/whitelist-source-range: "ips""} else print $0}' ips=$ips | \
    	awk '{if($2=="host:") {print "  - host : "hostname""} else print $0}' hostname=$cmsweb_hostname | \
        awk '{if($2=="cmsweb-test.cern.ch") {print "    - "hostname""} else print $0}' hostname=$cmsweb_hostname \
    	> $tmpDir/${ing}.yaml
	echo "deploy ingress: $tmpDir/${ing}.yaml"
        cat $tmpDir/${ing}.yaml
        kubectl apply -f $tmpDir/${ing}.yaml --validate=false
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
    done
}

deploy_services()
{
    echo
    echo "+++ deploy services: $cmsweb_srvs"
    for srv in $cmsweb_srvs; do
        if [ "$srv" == "dbs" ]; then
            for inst in $dbs_instances; do
                if [ -f "$sdir/${srv}-${inst}.yaml" ]; then
                    #kubectl apply -f "$sdir/${srv}-${inst}.yaml" --validate=false
                    cat $sdir/${srv}-${inst}.yaml | \
                        sed -e "s,replicas: 1 #PROD#,replicas: ,g" | \
                        sed -e "s,#PROD#,$prod_prefix,g" | \
                        sed -e "s,logs-cephfs-claim,logs-cephfs-claim$preprod_prefix,g" | \
                        kubectl apply --validate=false -f -
                fi
            done
        else
            if [ -f $sdir/${srv}.yaml ]; then
                #kubectl apply -f $sdir/${srv}.yaml --validate=false
                cat $sdir/${srv}.yaml | \
                    sed -e "s,replicas: 1 #PROD#,replicas: ,g" | \
                    sed -e "s,replicas: 2 #PROD#,replicas: ,g" | \
                    sed -e "s,#PROD#,$prod_prefix,g" | \
                    sed -e "s,logs-cephfs-claim,logs-cephfs-claim$preprod_prefix,g" | \
                    kubectl apply --validate=false -f -
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
        deploy_secrets
    elif [ "$deployment" == "ingress" ]; then
        deploy_ingress
    else
        deploy_ns
        deploy_secrets
        deploy_storages
        deploy_services
        deploy_roles
        deploy_ingress
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
