#!/bin/bash
. $(dirname $0)/sqoop_utils.sh
setJava

BASE_PATH="/project/awg/cms/phedex/block-replicas-snapshots/csv"
#BASE_PATH="transfermgmt"
JDBC_URL=$(sed '1q;d' cmsr_cstring)
USERNAME=$(sed '2q;d' cmsr_cstring)
PASSWORD=$(sed '3q;d' cmsr_cstring)

me=`basename $0`_$$

LOG_FILE=log/`date +'%F_%H%m%S'`_`basename $0`

year=`date +'%Y'`
month=`date +'%-m'`
day=`date +'%-d'`
TIME=`date +'%Hh%mm%Ss'`

OUTPUT_FOLDER=$BASE_PATH/time=`date +'%F'`_${TIME}
echo "Folder: $OUTPUT_FOLDER" >> $LOG_FILE.cron
echo "quering..." >> $LOG_FILE.cron
#exit;

sqoop import -Dmapreduce.job.user.classpath.first=true -Ddfs.client.socket-timeout=120000 --direct --connect $JDBC_URL --fetch-size 10000 --username $USERNAME --password $PASSWORD --target-dir $OUTPUT_FOLDER -m 1 \
--query "select cms_transfermgmt.now, ds.name as dataset_name, ds.id as dataset_id, ds.is_open as dataset_is_open, ds.time_create as dataset_time_create, ds.time_update as dataset_time_update, bk.name as block_name, bk.id as block_id, bk.files as block_files, bk.bytes as block_bytes, bk.is_open as block_is_open, bk.time_create as block_time_create, bk.time_update as block_time_update, n.name as node_name, n.id as node_id, br.is_active, br.src_files, br.src_bytes, br.dest_files, br.dest_bytes, br.node_files, br.node_bytes, br.xfer_files, br.xfer_bytes, br.is_custodial, br.user_group, br.time_create as replica_time_create, br.time_update as replica_time_update from cms_transfermgmt.t_dps_dataset ds join cms_transfermgmt.t_dps_block bk on bk.dataset=ds.id join cms_transfermgmt.t_dps_block_replica br on br.block=bk.id join cms_transfermgmt.t_adm_node n on n.id=br.node and \$CONDITIONS" \
--fields-terminated-by , --escaped-by \\ --optionally-enclosed-by '\"' \
1>$LOG_FILE.stdout 2>$LOG_FILE.stderr

if ! grep 'INFO mapreduce.ImportJobBase: Transferred' $LOG_FILE.stderr 1>/dev/null
then
	echo "Error occured, check $LOG_FILE"
	sendMail $LOG_FILE.stdout cms-transfermgmt-snapshot $START_DATE
	sendMail $LOG_FILE.stderr cms-transfermgmt-snapshot $START_DATE
fi

#hdfs dfs -put /tmp/$me.stdout $OUTPUT_FOLDER/sqoop.stdout && rm /tmp/$me.stdout
#hdfs dfs -put /tmp/$me.stderr $OUTPUT_FOLDER/sqoop.stderr && rm /tmp/$me.stderr
#rm /tmp/$$.stdout /tmp/$$.stderr
