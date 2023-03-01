#!/bin/bash
retryCount=0

echo "Checking MongoDB status:"

while [[ "$(mongo --quiet --eval "rs.status().ok")" != "0" ]]
do
    if [ $retryCount -gt 30 ]
    then
        echo "Retry count > 30, breaking out of while loop now..."
        break
    fi
    echo "MongoDB not ready for Replica Set configuration, retrying in 5 seconds..."
    sleep 5
    retryCount=$((retryCount+1))
done

sleep 5

if [[ $(mongo --quiet --eval "db.isMaster().setName") != $RS_NAME ]]
then
    echo "Replica Set reconfiguratoin failed..."
    echo "Reinitializing Replica Set..."
    /root/initialize-mongo-rs.sh &
else
    echo "Replica Set reconfiguratoin successful..."
fi