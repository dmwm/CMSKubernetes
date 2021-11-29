#!/bin/bash
# helper script to deploy given service with given tag to k8s infrastructure

if [ $# -lt 2 ]; then
     echo "The required parameters for service and tag are missing. Please use deploy-srv.sh <service> <tag> <env> "
     exit 1;
fi

cluster_name=`kubectl config get-clusters | grep -v NAME`
check=true

if [ $# -ne 3 ]; then
	if [[ "$cluster_name" == *"testbed"* ]] ; then
		env="preprod"
	fi
	if [[ "$cluster_name" == *"prod"* ]] ; then
                env="prod"
        fi
	if [[ "$cluster_name" == *"cmsweb-test1"* ]] ; then
                env="test1"
        fi
        if [[ "$cluster_name" == *"cmsweb-test2"* ]] ; then
                env="test2"
        fi
        if [[ "$cluster_name" == *"cmsweb-test3"* ]] ; then
                env="test3"
        fi
        if [[ "$cluster_name" == *"cmsweb-test4"* ]] ; then
                env="test4"
        fi
        if [[ "$cluster_name" == *"cmsweb-test5"* ]] ; then
                env="test5"
        fi
        if [[ "$cluster_name" == *"cmsweb-test6"* ]] ; then
                env="test6"
        fi
fi

srv=$1
cmsweb_image_tag=:$2

if [ $# == 3 ]; then
	env=$3
fi


cmsweb_env=k8s-$env
cmsweb_log=logs-cephfs-claim-$env



if [[ "$cluster_name" == *"testbed"* ]] ; then
        if [[ "$env" != "preprod" ]] ; then
        check=false
        fi
fi
if [[ "$cluster_name" == *"prod"* ]] ; then
        if [[ "$env" != "prod" ]] ; then
        check=false
        fi
fi
if [[ "$cluster_name"  == *"cmsweb-test1"* ]] ; then
        if [[ "$env" != "test1" ]] ; then
        check=false
        fi
fi

if [[ "$cluster_name"  == *"cmsweb-test2"* ]] ; then
        if [[ "$env" != "test2" ]] ; then
        check=false
        fi
fi
if [[ "$cluster_name"  == *"cmsweb-test3"* ]] ; then
        if [[ "$env" != "test3" ]] ; then
        check=false
        fi
fi
if [[ "$cluster_name"  == *"cmsweb-test4"* ]] ; then
        if [[ "$env" != "test4" ]] ; then
        check=false
        fi
fi
if [[ "$cluster_name"  == *"cmsweb-test5"* ]] ; then
        if [[ "$env" != "test5" ]] ; then
        check=false
        fi
fi
if [[ "$cluster_name"  == *"cmsweb-test6"* ]] ; then
        if [[ "$env" != "test6" ]] ; then
        check=false
        fi
fi


if [[ $check == false ]] ; then

        echo "The environment and config did not match. Please check."
        exit 1;
fi






tmpDir=/tmp/$USER/k8s/srv

# use tmp area to store service file
if [ -d $tmpDir ]; then
    rm -rf $tmpDir
fi
mkdir -p $tmpDir
cd $tmpDir
curl -ksLO https://raw.githubusercontent.com/dmwm/CMSKubernetes/master/kubernetes/cmsweb/services/$srv.yaml

# check that service file has imagetag
if [ -z "`grep imagetag $srv.yaml`" ]; then
    echo "unable to locate imagetag in $srv.yaml"
    exit 1
fi
echo "The downloaded and newly generated service manifest files are available at $tmpDir"
echo "Using Environment: $cmsweb_env"

# replace imagetag with real value and deploy new service
if [ "$cmsweb_env" == "k8s-prod" ] ; then

      cat $srv.yaml | sed -e "s,1 #PROD#,,g" | sed -e "s,#PROD#,      ,g" |  sed -e "s,logs-cephfs-claim,$cmsweb_log,g" | sed -e "s, #imagetag,$cmsweb_image_tag,g" | sed -e "s,k8s #k8s#,$cmsweb_env,g" > $srv.yaml.new
      cat $srv.yaml | sed -e "s,1 #PROD#,,g" | sed -e "s,#PROD#,      ,g" |  sed -e "s,logs-cephfs-claim,$cmsweb_log,g" | sed -e "s, #imagetag,$cmsweb_image_tag,g" | sed -e "s,k8s #k8s#,$cmsweb_env,g" | kubectl apply -f -

elif  [ "$cmsweb_env" == "k8s-preprod" ] ; then

	if [ "$srv" == "crabserver" ] ; then

            cat $srv.yaml | sed -e "s,1 #PROD#,,g" | sed -e "s,#PROD#,      ,g" |  sed -e "s,logs-cephfs-claim,$cmsweb_log,g" | sed -e "s, #imagetag,$cmsweb_image_tag,g" | sed -e "s,k8s #k8s#,$cmsweb_env,g" | sed -e 's+crabserver/prod+crabserver/preprod+g' >  $srv.yaml.new

            cat $srv.yaml | sed -e "s,1 #PROD#,,g" | sed -e "s,#PROD#,      ,g" |  sed -e "s,logs-cephfs-claim,$cmsweb_log,g" | sed -e "s, #imagetag,$cmsweb_image_tag,g" | sed -e "s,k8s #k8s#,$cmsweb_env,g" | sed -e 's+crabserver/prod+crabserver/preprod+g' |  kubectl apply -f -
 
        elif [[ "$srv" == "dbs-global-r"  || "$srv" == "dbs-global-w"  ||  "$srv" == "dbs-migrate"  ||  "$srv" == "dbs-phys03-r" || "$srv" == "dbs-phys03-w" ]] ; then
            cat $srv.yaml | sed -e "s,1 #PROD#,,g" | sed -e "s,#PROD#,      ,g" |  sed -e "s,logs-cephfs-claim,$cmsweb_log,g" | sed -e "s, #imagetag,$cmsweb_image_tag,g" | sed -e "s,k8s #k8s#,$cmsweb_env,g" | sed -e 's+dbs/prod+dbs/int+g' >  $srv.yaml.new

            cat $srv.yaml | sed -e "s,1 #PROD#,,g" | sed -e "s,#PROD#,      ,g" |  sed -e "s,logs-cephfs-claim,$cmsweb_log,g" | sed -e "s, #imagetag,$cmsweb_image_tag,g" | sed -e "s,k8s #k8s#,$cmsweb_env,g" | sed -e 's+dbs/prod+dbs/int+g' |  kubectl apply -f -
	
	else
            cat $srv.yaml | sed -e "s,1 #PROD#,,g" | sed -e "s,#PROD#,      ,g" |  sed -e "s,logs-cephfs-claim,$cmsweb_log,g" | sed -e "s, #imagetag,$cmsweb_image_tag,g" | sed -e "s,k8s #k8s#,$cmsweb_env,g" >  $srv.yaml.new

            cat $srv.yaml | sed -e "s,1 #PROD#,,g" | sed -e "s,#PROD#,      ,g" |  sed -e "s,logs-cephfs-claim,$cmsweb_log,g" | sed -e "s, #imagetag,$cmsweb_image_tag,g" | sed -e "s,k8s #k8s#,$cmsweb_env,g" | kubectl apply -f -
	fi

elif [ "$srv" == "crabserver" ]; then
            cat $srv.yaml | sed -e "s,1 #TEST#,,g" | sed -e "s,#TEST#,      ,g" | sed -e "s, #imagetag,$cmsweb_image_tag,g" |  sed -e 's+crabserver/prod+crabserver/preprod+g' | sed -e "s,k8s #k8s#,$cmsweb_env,g"  >  $srv.yaml.new
            cat $srv.yaml | sed -e "s,1 #TEST#,,g" | sed -e "s,#TEST#,      ,g" | sed -e "s, #imagetag,$cmsweb_image_tag,g" |  sed -e 's+crabserver/prod+crabserver/preprod+g' | sed -e "s,k8s #k8s#,$cmsweb_env,g" | kubectl apply -f -

elif [[ "$srv" == "dbs-global-r"  || "$srv" == "dbs-global-w"  ||  "$srv" == "dbs-migrate"  ||  "$srv" == "dbs-phys03-r" || "$srv" == "dbs-phys03-w" ]] ; then
        cat $srv.yaml | sed -e "s, #imagetag,$cmsweb_image_tag,g" |  sed -e 's+dbs/prod+dbs/dev+g' | sed -e "s,k8s #k8s#,$cmsweb_env,g"  >  $srv.yaml.new
        cat $srv.yaml | sed -e "s, #imagetag,$cmsweb_image_tag,g" |  sed -e 's+dbs/prod+dbs/dev+g' | sed -e "s,k8s #k8s#,$cmsweb_env,g"  | kubectl apply -f -
else 
        cat $srv.yaml | sed -e "s, #imagetag,$cmsweb_image_tag,g" | sed -e "s,k8s #k8s#,$cmsweb_env,g"  > $srv.yaml.new
        cat $srv.yaml | sed -e "s, #imagetag,$cmsweb_image_tag,g" | sed -e "s,k8s #k8s#,$cmsweb_env,g"  | kubectl apply -f -
fi

# return to original directory
cd -
