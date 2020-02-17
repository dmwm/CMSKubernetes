#!/bin/bash

# Prometheod metric based pod autoscaling
# Author: Valentin Kuznetsov < vkuznet AT gmail DOT com >
# Original idea:
# https://blog.powerupcloud.com/autoscaling-based-on-cpu-memory-in-kubernetes-part-ii-fe2e495bddd4
# https://github.com/powerupcloud/kubernetes-1/blob/master/memory-based-autoscaling.sh

TODAY=`date +%F`
KUBECTL=/usr/bin/kubectl
SCRIPT_HOME=$PWD/logs
if [ ! -d $SCRIPT_HOME ]; then
  mkdir -p $SCRIPT_HOME
fi

print_help(){
  echo "Use the following Command:"
  echo "./metric-autoscaling.sh"
  echo "        --action <action-name> --deployment <deployment-name>"
  echo "        --port <Prometheus port number> --metric <Prometheus metric>"
  echo "        --scaleup <scaleupthreshold> --scaledown <scaledownthreshold>"
  printf "Choose one of the available actions below:\n"
  printf "  get-metric\n  list-metrics\n  deploy-autoscaling\n"
  echo "You can get the list of existing deployments using command: kubectl get deployments"
  echo
  echo "Example, scale DBS pod based on memory metric"
  echo "./metric-autoscaling.sh"
  echo "         --action deploy-autoscaling --deployment dbs-global-r"
  echo "         --port 18252 --metric dbs_global_exporter_memory_percent"
  echo "         --scaleup 80 --scaledown 20"
}
ARG="$#"
if [[ $ARG -eq 0 ]]; then
  print_help
  exit
fi

while test -n "$1"; do
   case "$1" in
        --action)
            ACTION=$2
            shift
            ;;
        --metric)
            METRIC=$2
            shift
            ;;
        --port)
            PORT=$2
            shift
            ;;
        --deployment)
            DEPLOYMENT=$2
            shift
            ;;
        --scaleup)
            SCALEUPTHRESHOLD=$2
            shift
            ;;
        --scaledown)
            SCALEDOWNTHRESHOLD=$2
            shift
            ;;
       *)
            print_help
            exit
            ;;
   esac
    shift
done

LOG_FILE=$SCRIPT_HOME/kube-$DEPLOYMENT-$TODAY.log
touch $LOG_FILE

REPLICAS=`$KUBECTL get deployment | grep $DEPLOYMENT | awk '{print $4}' | grep -v "CURRENT"`

#########################################

get_metric(){
  echo "===========================" >> $LOG_FILE
  pods=`$KUBECTL get pod | grep $DEPLOYMENT | awk '{print $1}' | grep -v NAME`
  for i in $pods
    do
      echo "Pod: "$i >> $LOG_FILE

      val=`$KUBECTL exec -it $i -- curl http://localhost:$PORT/metrics | grep ^$METRIC | awk '{print $2}'`
      echo "Used $METRIC: "$val"" >> $LOG_FILE
      echo "===========================" >> $LOG_FILE
    done
  intVal=`echo $val | awk '{split($0,a,"."); print a[1]}'`
  AVGMETRICVALUE=$(( $intVal/$REPLICAS ))
  echo "Average $METRIC value: "$AVGMETRICVALUE
  echo "Average $METRIC value: "$AVGMETRICVALUE >> $LOG_FILE
}

#########################################

list_metrics(){
  echo "===========================" >> $LOG_FILE
  pods=`$KUBECTL get pod | grep $DEPLOYMENT | awk '{print $1}' | grep -v NAME`
  for i in $pods
    do
      echo "Pod: "$i >> $LOG_FILE

      $KUBECTL exec -it $i -- curl http://localhost:$PORT/metrics | grep -v "#" | awk '{print $1}'
    done
}

#########################################

metric_autoscale(){
  if [ $AVGMETRICVALUE -gt $SCALEUPTHRESHOLD ]
  then
      echo "Metric ($METRIC) is greater than the threshold" >> $LOG_FILE
      count=$((REPLICAS+1))
      echo "Updated number of replicas will be: "$count >> $LOG_FILE
      scale=`$KUBECTL scale --replicas=$count deployment/$DEPLOYMENT`
      echo "Deployment Scaled Up" >> $LOG_FILE

  elif [ $AVGMETRICVALUE -lt $SCALEDOWNTHRESHOLD ] && [ $REPLICAS -gt 2 ]
  then
      echo "Metric ($METRIC) is less than threshold" >> $LOG_FILE
      count=$((REPLICAS-1))
      echo "Updated number of replicas will be: "$count >> $LOG_FILE
      scale=`$KUBECTL scale --replicas=$count deployment/$DEPLOYMENT`
      echo "Deployment Scaled Down" >> $LOG_FILE
  else
      echo "Metric ($METRIC) is not crossing the threshold. No Scaling Done." >> $LOG_FILE
  fi
}

##########################################

if [[ $REPLICAS ]]; then
  if [ "$ACTION" = "deploy-autoscaling" ];then
      if [ $ARG -ne 12 ]
      then
        echo "Incorrect number of arguments provided"
        print_help
        exit 1
      fi
      get_metric
      metric_autoscale
  elif [ "$ACTION" = "get-metric" ];then
      if [ $ARG -ne 8 ]
      then
        echo "Incorrect number of arguments provided"
        print_help
        exit 1
      fi
      get_metric
  elif [ "$ACTION" = "list-metrics" ];then
      if [ $ARG -ne 6 ]
      then
        echo "Incorrect number of arguments provided"
        print_help
        exit 1
      fi
      list_metrics
  else
      echo "Unknown Action"
      print_help
  fi
else
  echo "No Deployment exists with name: "$DEPLOYMENT
  print_help
fi
