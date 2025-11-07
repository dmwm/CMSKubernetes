#!/bin/bash

# Scales down all DBS deployments in the current K8 cluster for a given interval of time in sec.
# If no interval has been provided, scales down all of them and exits

interval=$1

# Build a list of all current replicas in each deployment:
deployList=`kubectl -n dbs get deploy |grep dbs2go |awk '{print  $1":"$3}'`
echo $deployList

# Scale down all deployments:
for depl in $deployList
do
    repl=${depl#*:}; depl=${depl%:*};
    echo Scaling down: ${depl}:0
    kubectl -n dbs scale deploy $depl --replicas=0
done

# Exit here if no interval has been provided
[[ -z $interval ]] && exit 0

# Wait before scaling up again:
while [[ $interval -ne 0 ]]; do echo $interval; sleep 1; let "interval--"; done

# Scale up again to the original number of replicas
for depl in $deployList
do
    repl=${depl#*:}; depl=${depl%:*};
    echo Scaling up: ${depl}:$repl
    kubectl -n dbs scale deploy $depl --replicas=$repl
done
