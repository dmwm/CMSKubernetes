#!/bin/bash
# helper script to deploy WMCore Services()"reqmgr2ms-output" "reqmgr2ms-rulecleaner" "reqmgr2ms-transferor" "reqmgr2ms-unmerged-t1" "reqmgr2ms-unmerged-t2t3" "reqmgr2ms-unmerged-t2t3us" "reqmgr2" "reqmgr2-tasks" "reqmon" "reqmon-tasks" "workqueue" "t0_reqmon" "t0_reqmon-tasks" "t0wmadatasvc" with given tag to k8s infrastructure

if [ $# -lt 1 ]; then
     echo "The required parameters are missing. Please use deploy-srv-wmcore.sh <tag> <env> "
     exit 1;
fi

cluster_name=`kubectl config get-clusters | grep -v NAME`
check=true

if [ $# -ne 2 ]; then
	if [[ "$cluster_name" == *"testbed"* ]] ; then
		env="preprod"
	fi
	if [[ "$cluster_name" == *"prod"* ]] ; then
                env="prod"
        fi
        if [[ "$cluster_name" == *"cmsweb-auth"* ]] ; then
                env="auth"
        fi
	if [[ "$cluster_name" == *"cmsweb-test1" ]] ; then
                env="test1"
		echo "test1"
        fi
        if [[ "$cluster_name" == *"cmsweb-test2" ]] ; then
                env="test2"
        fi
        if [[ "$cluster_name" == *"cmsweb-test3" ]] ; then
                env="test3"
        fi
        if [[ "$cluster_name" == *"cmsweb-test4" ]] ; then
                env="test4"
        fi
        if [[ "$cluster_name" == *"cmsweb-test5" ]] ; then
                env="test5"
        fi
        if [[ "$cluster_name" == *"cmsweb-test6" ]] ; then
                env="test6"
        fi
        if [[ "$cluster_name" == *"cmsweb-test7" ]] ; then
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
        if [[ "$cluster_name" == *"cmsweb-test12" ]] ; then
                env="test12"
        fi
        if [[ "$cluster_name" == *"cmsweb-test13" ]] ; then
                env="test13"
        fi

	
fi
srv=( "reqmgr2ms-output" "reqmgr2ms-rulecleaner" "reqmgr2ms-transferor" "reqmgr2ms-unmerged-t1" "reqmgr2ms-unmerged-t2t3" "reqmgr2ms-unmerged-t2t3us" "reqmgr2ms-pileup" "reqmgr2ms-pileup-tasks" "reqmgr2" "reqmgr2-tasks" "reqmon" "reqmon-tasks" "workqueue" "t0_reqmon" "t0_reqmon-tasks" )
echo ${srv[*]}


cmsweb_image_tag=:$1

if [ $# == 2 ]; then
	env=$2
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
if [[ "$cluster_name"  == *"cmsweb-auth"* ]] ; then
        if [[ "$env" != "auth" ]] ; then
        check=false
        fi
fi

if [[ "$cluster_name"  == *"cmsweb-test1" ]] ; then
        if [[ "$env" != "test1" ]] ; then
        check=false
        fi
fi

if [[ "$cluster_name"  == *"cmsweb-test2" ]] ; then
        if [[ "$env" != "test2" ]] ; then
        check=false
        fi
fi
if [[ "$cluster_name"  == *"cmsweb-test3" ]] ; then
        if [[ "$env" != "test3" ]] ; then
        check=false
        fi
fi
if [[ "$cluster_name"  == *"cmsweb-test4" ]] ; then
        if [[ "$env" != "test4" ]] ; then
        check=false
        fi
fi
if [[ "$cluster_name"  == *"cmsweb-test5" ]] ; then
        if [[ "$env" != "test5" ]] ; then
        check=false
        fi
fi
if [[ "$cluster_name"  == *"cmsweb-test6" ]] ; then
        if [[ "$env" != "test6" ]] ; then
        check=false
        fi
fi
if [[ "$cluster_name"  == *"cmsweb-test7" ]] ; then
        if [[ "$env" != "test7" ]] ; then
        check=false
        fi
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
if [[ "$cluster_name"  == *"cmsweb-test12" ]] ; then
        if [[ "$env" != "test12" ]] ; then
        check=false
        fi
fi
if [[ "$cluster_name"  == *"cmsweb-test13" ]] ; then
        if [[ "$env" != "test13" ]] ; then
        check=false
        fi
fi

if [[ $check == false ]] ; then

        echo "The environment and config did not match. Please check."
        exit 1;
fi


for i in "${srv[@]}"
do

        tmpDir=/tmp/$USER/k8s/srv

        # use tmp area to store service file
        if [ -d $tmpDir ]; then
        rm -rf $tmpDir
        fi
        mkdir -p $tmpDir
        cd $tmpDir
        curl -ksLO https://raw.githubusercontent.com/dmwm/CMSKubernetes/master/kubernetes/cmsweb/services/$i.yaml

        # check that service file has imagetag
        if [ -z "`grep imagetag $i.yaml`" ]; then
         echo $i
         echo "unable to locate imagetag in $i.yaml"
        exit 1
        fi
        echo "The downloaded and newly generated service manifest files are available at $tmpDir"
        echo "Using Environment: $cmsweb_env"

        # replace imagetag with real value and deploy new service
        if [ "$cmsweb_env" == "k8s-prod" || "$cmsweb_env" == "k8s-preprod" ] ; then

         cat $i.yaml | sed -e "s,1 #PROD#,,g" | sed -e "s,#PROD#,      ,g" |  sed -e "s,logs-cephfs-claim,$cmsweb_log,g" | sed -e "s, #imagetag,$cmsweb_image_tag,g" | sed -e "s,k8s #k8s#,$cmsweb_env,g" > $i.yaml.new
         cat $i.yaml | sed -e "s,1 #PROD#,,g" | sed -e "s,#PROD#,      ,g" |  sed -e "s,logs-cephfs-claim,$cmsweb_log,g" | sed -e "s, #imagetag,$cmsweb_image_tag,g" | sed -e "s,k8s #k8s#,$cmsweb_env,g" | kubectl apply -f -

        else 
        cat $i.yaml | sed -e "s, #imagetag,$cmsweb_image_tag,g" | sed -e "s,k8s #k8s#,$cmsweb_env,g"  > $i.yaml.new
        cat $i.yaml | sed -e "s, #imagetag,$cmsweb_image_tag,g" | sed -e "s,k8s #k8s#,$cmsweb_env,g"  | kubectl apply -f -
        fi

# return to original directory
        cd -
done
