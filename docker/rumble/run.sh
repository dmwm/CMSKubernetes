#!/bin/bash

# Kerberos
keytab=/etc/rumble/keytab
principal=`klist -k "$keytab" | tail -1 | awk '{print $2}'`
echo "principal=$principal"
kinit $principal -k -t "$keytab"
if [ $? == 1 ]; then
    echo "Unable to perform kinit"
    exit 1
fi
klist -k "$keytab"


# Start crond if it is not runing
if [ -z "`ps auxww | grep crond | grep -v grep`" ]; then
    crond -n &
fi


# Spark
spark_submit=/usr/hdp/spark-3.0/bin/spark-submit
rumble=/data/spark-rumble.jar

spark_confs=(
    --conf spark.driver.bindAddress=0.0.0.0
    --conf spark.driver.host=test-cluster-jnbxujghdusq-node-0
    --conf spark.driver.port=32000
    --conf spark.driver.blockManager.port=32001
)

# Prod configs of spark-submit
spark_server_confs=(
    --verbose
    --executor-cores 4
    --executor-memory 20G
)

# Server mode configs of rumble
rumble_server_params=(
    --server yes
    --port 8001
    --host 0.0.0.0
)

run_server()
{
    echo "Startting rumble server:"
    echo "nohup" $spark_submit ${spark_server_confs[@]} ${spark_confs[@]} $rumble ${rumble_server_params[@]} "2>&1 1>& server.log < /dev/null &"
    echo "\n"
    cd /data; nohup $spark_submit ${spark_server_confs[@]} ${spark_confs[@]} $rumble ${rumble_server_params[@]} 2>&1 1>& server.log < /dev/null &
    echo $!
    echo "Running rumble as a server."
}

run_server
