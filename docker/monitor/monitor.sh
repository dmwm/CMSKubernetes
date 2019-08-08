#!/bin/bash

if [ $# -ne 7 ]; then
    echo "Usage: monitor.sh <service> <port> <query> <down_threshold> <up_threshold> <min_replicas> <max_replicas>"
    exit 1
fi

SRV=$1
PORT=$2
METRIC=$3
DOWN_THR=$4
UP_THR=$5
MIN_REPLICAS=$6
MAX_REPLICAS=$7

REPLICAS=`kubectl get deployment | grep $SRV | awk '{print $4}' | grep -v "CURRENT"`
prom=`which prometheus-query`
if [ -f $prom ]; then
    # prom command return time series for a given metric
    # the format we get from prom command is
    # time,metric
    # 123,123
    # therefore we extract last column and obtain its average
    echo "$prom -server=http://$SRV:$PORT -query \"$METRIC\" -format csv | egrep \"^[[:digit:]]\" | awk 'END{print i/t} {split(\$1,a,\",\"); i+=a[2]; t+=1}'"
    $prom -server=http://$SRV:$PORT -query "$METRIC" -format csv | \
        egrep "^[[:digit:]]" | awk 'END{print i/t} {split($1,a,","); i+=a[2]; t+=1}'
else
    # if we didn't find prom command we use current metric value
    echo "curl -s http://$SRV:$PORT/metrics | grep ^$METRIC | awk '{print $2}'"
    val=`curl -s http://$SRV:$PORT/metrics | grep ^$METRIC | awk '{print $2}'`
    intVal=`echo $val | awk '{split($0,a,"."); print a[1]}'`
    AVG=$(( $intVal/$REPLICAS ))
fi
echo "service: $SRV port: $PORT metric: $METRIC threshold: $DOWN_THR-$UP_THR replicas: $REPLICAS val: $intVal avg: $AVG"

if [ $AVG -gt $UP_THR ]
then
    echo "METRIC ($METRIC) is greater than the threshold"
    if [ $REPLICAS -eq $MAX_REPLICAS ]; then
        echo "Can't scale up, reached capacity of the max replicas"
    else
        count=$((REPLICAS+1))
        echo "Updated number of replicas will be: "$count
        scale=`kubectl scale --replicas=$count deployment/$SRV`
        echo "Deployment scaled up"
    fi

elif [ $AVG -lt $DOWN_THR ]
then
    echo "METRIC ($METRIC) is less than threshold"
    if [ $REPLICAS -eq $MIN_REPLICAS ]; then
        echo "Can't scale down, reached capacity of the min replicas"
    elif [ $REPLICAS -eq 1 ]; then
        echo "Can't scale down, only 1 running replica left"
    else
        count=$((REPLICAS-1))
        echo "Updated number of replicas will be: "$count
        scale=`kubectl scale --replicas=$count deployment/$SRV`
        echo "Deployment scaled down"
    fi
else
    echo "METRIC ($METRIC) is not crossing the threshold. No Scaling Done."
fi
