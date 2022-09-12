#!/bin/bash
# helper script to deploy given service with given tag to k8s infrastructure

if [ $# -lt 2 ]; then
     echo "The required parameters for service and tag are missing. Please use deploy-ds.sh <daemonset-name> <tag> <env> "
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
        if [[ "$cluster_name" == *"cmsweb-auth"* ]] ; then
                env="auth"
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
        if [[ "$cluster_name" == *"cmsweb-test7"* ]] ; then
                env="test7"
        fi
        if [[ "$cluster_name" == *"cmsweb-test8" ]] ; then
                env="test8"
        fi
        if [[ "$cluster_name" == *"cmsweb-test9" ]] ; then
                env="test9"
        fi
        if [[ "$cluster_name" == *"cmsweb-test10" ]] ; then
                env="test10"
        fi
        if [[ "$cluster_name" == *"cmsweb-test11" ]] ; then
                env="test11"
        fi

fi

srv=$1
cmsweb_image_tag=:$2

echo $srv
echo $cmsweb_image_tag

if [ $# == 3 ]; then
	env=$3
fi


cmsweb_env=k8s-$env
cmsweb_log=logs-cephfs-claim-$env

echo $cmsweb_env
echo $cmsweb_log

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
if [[ "$cluster_name"  == *"cmsweb-auth"* ]] ; then
        if [[ "$env" != "auth" ]] ; then
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

if [[ "$cluster_name"  == *"cmsweb-test7"* ]] ; then
        if [[ "$env" != "test7" ]] ; then
        check=false
        fi
fi
if [[ $check == false ]] ; then

        echo "The environment and config did not match. Please check."
        exit 1;
fi
if [[ "$cluster_name"  == *"cmsweb-test8" ]] ; then
        if [[ "$env" != "test8" ]] ; then
        check=false
        fi
fi
if [[ "$cluster_name"  == *"cmsweb-test9" ]] ; then
        if [[ "$env" != "test9" ]] ; then
        check=false
        fi
fi
if [[ "$cluster_name"  == *"cmsweb-test10" ]] ; then
        if [[ "$env" != "test10" ]] ; then
        check=false
        fi
fi
if [[ "$cluster_name"  == *"cmsweb-test11" ]] ; then
        if [[ "$env" != "test11" ]] ; then
        check=false
        fi
fi






tmpDir=/tmp/$USER/k8s/srv

# use tmp area to store service file
if [ -d $tmpDir ]; then
    rm -rf $tmpDir
fi
mkdir -p $tmpDir
cd $tmpDir
curl -ksLO https://raw.githubusercontent.com/dmwm/CMSKubernetes/master/kubernetes/cmsweb/daemonset/$srv.yaml

# check that service file has imagetag
if [ -z "`grep imagetag $srv.yaml`" ]; then
    echo "unable to locate imagetag in $srv.yaml"
    exit 1
fi
echo "The downloaded and newly generated service manifest files are available at $tmpDir"
echo "Using Environment: $cmsweb_env"

# replace imagetag with real value and deploy new service
if [ "$cmsweb_env" == "k8s-prod" ] || [ "$cmsweb_env" == "k8s-preprod" ] ; then

      cat $srv.yaml | sed -e "s,1 #PROD#,,g" | sed -e "s,#PROD#,      ,g" |  sed -e "s,logs-cephfs-claim,$cmsweb_log,g" | sed -e "s, #imagetag,$cmsweb_image_tag,g" | sed -e "s,k8s #k8s#,$cmsweb_env,g" > $srv.yaml.new
      cat $srv.yaml | sed -e "s,1 #PROD#,,g" | sed -e "s,#PROD#,      ,g" |  sed -e "s,logs-cephfs-claim,$cmsweb_log,g" | sed -e "s, #imagetag,$cmsweb_image_tag,g" | sed -e "s,k8s #k8s#,$cmsweb_env,g" | kubectl apply -f -

else 
        cat $srv.yaml | sed -e "s, #imagetag,$cmsweb_image_tag,g" | sed -e "s,k8s #k8s#,$cmsweb_env,g"  > $srv.yaml.new
        cat $srv.yaml | sed -e "s, #imagetag,$cmsweb_image_tag,g" | sed -e "s,k8s #k8s#,$cmsweb_env,g"  | kubectl apply -f -
fi

# return to original directory
cd -
