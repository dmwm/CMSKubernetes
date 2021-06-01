#!/bin/bash

if [ $# -lt 2 ]; then
     echo "Usage Instructions: <bucket-path> <backup service-name>"
     echo "victoria-metrics-restore.sh cms-monitoring/vmbackup/2021/05/31/00:00 victoria-metrics"
     echo "victoria-metrics-restore.sh cms-monitoring/vmbackup-long/2021/05/31/00:00 victoria-metrics-long"
     exit 1;
fi

bucket_path=$1
backup_service=$2

# use tmp area to store service file
tmpDir=/tmp/$USER/k8s/
if [ -d $tmpDir ]; then
    rm -rf $tmpDir
fi
mkdir -p $tmpDir
cd $tmpDir

curl -ksLO https://raw.githubusercontent.com/dmwm/CMSKubernetes/master/kubernetes/monitoring/services/agg/vmrestore.yaml
#ls $tmpDir

if [[ "$backup_service"  == "victoria-metrics" ]] ; then

  cat vmrestore.yaml | sed -e "s,cms-monitoring/vmbackup/2021/05/31/00:00,$bucket_path,g" > vmrestore.yaml.new
  
  curl -ksLO https://raw.githubusercontent.com/dmwm/CMSKubernetes/master/kubernetes/monitoring/services/agg/victoria-metrics.yaml

  kubectl delete -f victoria-metrics.yaml
  a=0
  while [ $a -lt 50 ]
  do
    sleep 5s
    pod=`kubectl get pods | grep victoria-metrics | grep -v long`
    if [ -z "$pod" ]
    then
      break 
    else
      a=`expr $a + 1`
    fi

    if [ $a -eq 50 ] ; then 
       exit 1;
    fi

  done

  kubectl apply -f vmrestore.yaml.new

  a=0
  while [ $a -lt 50 ]
  do
    sleep 5s	  
    job=`kubectl get pods | grep vmrestore | awk '{print $3}'`
    if [[ "$job"  == "Completed" ]] ; then
      break
    else
      a=`expr $a + 1`
    fi
    if [ $a -eq 50 ] ; then
       exit 1;
    fi

  done

  kubectl delete -f vmrestore.yaml.new

  kubectl apply -f victoria-metrics.yaml


fi

if [[ "$backup_service"  == "victoria-metrics-long" ]] ; then

  cat vmrestore.yaml | sed -e "s,cms-monitoring/vmbackup/2021/05/31/00:00,$bucket_path,g" | sed -e "s,vm-volume-claim,vm-volume-long-claim,g" > vmrestore.yaml.new

  curl -ksLO https://raw.githubusercontent.com/dmwm/CMSKubernetes/master/kubernetes/monitoring/services/agg/victoria-metrics-long.yaml


  kubectl delete -f victoria-metrics-long.yaml

  a=0
  while [ $a -lt 50 ]
  do
    sleep 5s
    pod=`kubectl get pods | grep victoria-metrics-long`
    if [ -z "$pod" ]
    then
      break
    else
      a=`expr $a + 1`
    fi
    if [ $a -eq 50 ] ; then
       exit 1;
    fi

  done


  kubectl apply -f vmrestore.yaml.new

  a=0
  while [ $a -lt 50 ]
  do
    sleep 5s
    job=`kubectl get pods | grep vmrestore | awk '{print $3}'`
    if [[ "$job"  == "Completed" ]] ; then
      break
    else
      a=`expr $a + 1`
    fi
    if [ $a -eq 50 ] ; then
       exit 1;
    fi
  done

  kubectl delete -f vmrestore.yaml.new

  kubectl apply -f victoria-metrics-long.yaml

fi

# return to original directory
cd -
