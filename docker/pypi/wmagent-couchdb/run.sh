#!/bin/bash
echo "start sleeping....zzz"
while true; do sleep 10; done


# # start the service
# manage start





# ###########################################################################################
# # NOTE: Leftovers - to be adopted/reimplemented in the GH issue dealing with CouchDB setup
# #       all of those steps were previously done with the old wmagent deployment procedures
# ###########################################################################################

# DATA_SIZE=`lsblk -bo SIZE,MOUNTPOINT | grep ' /data1' | sort | uniq | awk '{print $1}'`
# DATA_SIZE_GB=`lsblk -o SIZE,MOUNTPOINT | grep ' /data1' | sort | uniq | awk '{print $1}'`
# if [[ $DATA_SIZE -gt 200000000000 ]]; then  # greater than ~200GB
# echo "Partition /data1 available! Total size: $DATA_SIZE_GB"
# sleep 0.5
# while true; do
# read -p "Would you like to deploy couchdb in this /data1 partition (yes/no)? " yn
# case $yn in
# [Y/y]* ) DATA1=true; break;;
# [N/n]* ) DATA1=false; break;;
# * ) echo "Please answer yes or no.";;
# esac
# done
# else
# DATA1=false
# fi && echo

# echo -e "\n*** Applying (for couchdb1.6, etc) cert file permission ***"
# chmod 600 /data/certs/service{cert,key}.pem
# echo "Done!"

# echo "*** Checking if couchdb migration is needed ***"
# echo -e "\n[query_server_config]\nos_process_limit = 50" >> $WMA_CURRENT_DIR/config/couchdb/local.ini
# if [ "$DATA1" = true ]; then
# ./manage stop-services
# sleep 5
# if [ -d "/data1/database/" ]; then
# echo "Moving old database away... "
# mv /data1/database/ /data1/database_old/
# FINAL_MSG="5) Remove the old database when possible (/data1/database_old/)"
# fi
# rsync --remove-source-files -avr /data/srv/wmagent/current/install/couchdb/database /data1
# sed -i "s+database_dir = .*+database_dir = /data1/database+" $WMA_CURRENT_DIR/config/couchdb/local.ini
# sed -i "s+view_index_dir = .*+view_index_dir = /data1/database+" $WMA_CURRENT_DIR/config/couchdb/local.ini
# ./manage start-services
# fi
# echo "Done!" && echo
# ###########################################################################################
