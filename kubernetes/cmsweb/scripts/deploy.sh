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
##H   daemonset  deploy cluster's daemonsets
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
sdir=services
mdir=monitoring
idir=ingress
cdir=crons

# cmsweb service namespaces
#cmsweb_ns=`grep namespace $sdir/* | awk '{print $3}' | sort | uniq | grep -v default | grep -v phedex | grep -v couchdb | grep -v dqm | grep -v auth | grep -v mongodb | grep -v udp | grep -v tfaas`
cmsweb_ns="default crab das dbs dmwm http tzero wma"
# services for cmsweb cluster, adjust if necessary
#cmsweb_ing="ing-srv"
#cmsweb_ing="ing-couchdb ing-crab ing-dbs ing-das ing-dmwm ing-dqm ing-http ing-phedex ing-tzero ing-exitcodes"
cmsweb_ing="ing-crab ing-dbs ing-das ing-dmwm ing-http ing-tzero ing-exitcodes ing-wma"
cmsweb_ds=""

#cmsweb_srvs="httpgo httpsgo frontend acdcserver couchdb crabcache crabserver das dbs dqmgui phedex reqmgr2 reqmgr2-tasks reqmgr2ms reqmon t0_reqmon t0wmadatasvc workqueue workqueue-tasks exitcodes"

cmsweb_srvs="httpgo httpsgo frontend crabcache crabserver das-server das-mongo das-mongo-exporter dbs dbsmigration reqmgr2 reqmgr2-tasks reqmgr2ms-monitor reqmgr2ms-output reqmgr2ms-transferor reqmon reqmon-tasks t0_reqmon t0_reqmon-tasks t0wmadatasvc workqueue exitcodes wmarchive"

# list of DBS instances
dbs_instances="migrate  global-r global-w phys03-r phys03-w"

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
    cmsweb_ing="ing-crab ing-dbs ing-das ing-dmwm ing-http ing-tzero ing-exitcodes ing-wma"

    #cmsweb_srvs="httpgo httpsgo acdcserver couchdb crabcache crabserver das dbs dqmgui phedex reqmgr2 reqmgr2-tasks reqmgr2ms reqmon t0_reqmon t0wmadatasvc workqueue workqueue-tasks exitcodes"
cmsweb_srvs="httpgo httpsgo crabcache crabserver das-server das-mongo das-mongo-exporter dbs dbsmigration reqmgr2 reqmgr2-tasks reqmgr2ms-monitor reqmgr2ms-output reqmgr2ms-transferor  reqmon reqmon-tasks t0_reqmon t0_reqmon-tasks t0wmadatasvc workqueue exitcodes wmarchive"

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
    cmsweb_ds="frontend"
    echo "+++ deploy daemonset: $cmsweb_ds"
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

    # delete daemonset
    echo "--- delete daemonset"
    for ds in $cmsweb_ds; do
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
    local namespaces="$cmsweb_ns"
    for ns in $namespaces; do
        echo "---"
        echo "Create secrets in namespace: $ns"

        # create secrets with our robot certificates
        kubectl create secret generic robot-secrets \
            --from-file=$robot_key --from-file=$robot_crt \
            $files --dry-run -o yaml | \
            kubectl apply --namespace=$ns -f -

        # create proxy secret
        if [ -f $proxy ]; then
            kubectl create secret generic proxy-secrets \
                --from-file=$proxy --dry-run -o yaml | \
                kubectl apply --namespace=$ns -f -
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
                        --from-file=$robot_key --from-file=$robot_crt \
                        --from-file=$hmac \
                        $files $dbsfiles --dry-run -o yaml | \
                        kubectl apply --namespace=$ns -f -
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
                    kubectl apply --namespace=$ns -f -
            fi
        done

    done

    # create ingress secrets file, it requires tls.key/tls.crt files
    kubectl create secret generic ing-secrets \
        --from-file=$tls_key --from-file=$tls_crt --dry-run -o yaml | \
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

    echo
    echo "+++ deploy monitoring services"
    # add kube-eagle
    kubectl apply -f monitoring/kube-eagle.yaml
    # use common logstash yaml for ALL services
    #kubectl -n monitoring apply -f monitoring/logstash.yaml
    cat monitoring/logstash.yaml | \
        sed -e "s,dev # cmsweb_env,$env_prefix,g" | \
        sed -e "s,dev # cluster,$cluster,g" | \
        kubectl -n monitoring apply -f -
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
    if [ "$deployment" == "services" ]; then
        mon="services"
    elif [ "$deployment" == "frontend" ]; then
        mon="frontend"
    fi
    local files=""
    if [ -d monitoring ] && [ -n "`ls monitoring/prometheus/$mon`" ]; then
        # change "k8s" env label in prometheus.yaml files based on our cmsweb environment
        if [ -f monitoring/prometheus/$mon/prometheus.yaml ]; then
            if [ "$CMSWEB_ENV" == "production" ] || [ "$CMSWEB_ENV" == "prod" ]; then
                cat monitoring/prometheus/$mon/prometheus.yaml | sed -e 's,"k8s","k8s-prod",g' > /tmp/prometheus.yaml
            fi
            if [ "$CMSWEB_ENV" == "preproduction" ] || [ "$CMSWEB_ENV" == "preprod" ]; then
                cat monitoring/prometheus/$mon/prometheus.yaml | sed -e 's,"k8s","k8s-preprod",g' > /tmp/prometheus.yaml
            fi
        fi
        if [ -f /tmp/prometheus.yaml ]; then
            files="$files --from-file=/tmp/prometheus.yaml"
        else
            files="$files --from-file=/monitoring/prometheus/$mon/prometheus.yaml"
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
    kubectl create configmap logstash \
        --from-file=monitoring/logstash.conf --from-file=monitoring/logstash.yml -n monitoring

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
    #kubectl apply -f storages/cinder-storage.yaml
}

# deploy cluster roles
deploy_roles()
{
    kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
}

# deploy appripriate daemonset for our cluster
deploy_daemonset()
{
    kubectl get nodes | grep node | awk '{print $1}' | awk '{print "kubectl label node "$1" role=auth --overwrite"}'
    for ds in $cmsweb_ds; do
        kubectl apply -f daemonset/${ds}.yaml
    done
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
	                        kubectl apply -f $sdir/${srv}-${inst}.yaml
			fi
                fi
            done
        else
            if [ -f $sdir/${srv}.yaml ]; then
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
			kubectl apply -f $sdir/${srv}.yaml
		fi

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
    elif [ "$deployment" == "daemonset" ]; then
        deploy_daemonset
    elif [ "$deployment" == "monitoring_backend" ]; then
        deployment=services
        deploy_monitoring
    elif [ "$deployment" == "monitoring_frontend" ]; then
        deployment=frontend
        deploy_monitoring
    else
        deploy_ns
        deploy_secrets
	if [[ ("$CMSWEB_ENV" == "production"  ||  "$CMSWEB_ENV" == "prod"  ||  "$CMSWEB_ENV" == "preproduction"  ||  "$CMSWEB_ENV" == "preprod")  && ("$deployment" == "services") ]]; then
     		deploy_storages
	fi
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
