#!/bin/bash
. $(dirname $0)/sqoop_utils.sh
setJava
BASE_PATH="/project/awg/cms/phedex/catalog/csv"
#BASE_PATH="cms-catalog"
JDBC_URL=$(sed '1q;d' cmsr_cstring)
USERNAME=$(sed '2q;d' cmsr_cstring)
PASSWORD=$(sed '3q;d' cmsr_cstring)

me=`basename $0`_$$

if [ -n "$1" ]
then
	START_DATE=$1
else
	START_DATE=`date +'%F' -d "1 day ago"`
fi

year=`date +'%Y' -d "$START_DATE"`
month=`date +'%-m' -d "$START_DATE"`
day=`date +'%-d' -d "$START_DATE"`
END_DATE=`date +'%F' -d "$START_DATE + 1 day"`

START_DATE_S=`date +'%s' -d "$START_DATE"`
END_DATE_S=`date +'%s' -d "$END_DATE"`

LOG_FILE=log/`date +'%F_%H%m%S'`_`basename $0`

OUTPUT_FOLDER=$BASE_PATH/diff/date=$START_DATE
MERGED_FOLDER=$BASE_PATH/merged
echo "Timerange: $START_DATE to $END_DATE" >> $LOG_FILE.cron
echo "Folder: $OUTPUT_FOLDER" >> $LOG_FILE.cron
echo "quering..." >> $LOG_FILE.cron
#exit;

sqoop import -Dmapreduce.job.user.classpath.first=true -Ddfs.client.socket-timeout=120000 --direct --connect $JDBC_URL --fetch-size 10000 --username $USERNAME --password $PASSWORD --target-dir $OUTPUT_FOLDER -m 1 \
--query "select ds.name as dataset_name, ds.id as dataset_id, ds.is_open as dataset_is_open, ds.time_create as dataset_time_create, bk.name as block_name, bk.id as block_id, bk.time_create as block_time_create, bk.is_open as block_is_open, f.logical_name as file_lfn, f.id as file_id, f.filesize, f.checksum, f.time_create as file_time_create from cms_transfermgmt.t_dps_dataset ds join cms_transfermgmt.t_dps_block bk on bk.dataset=ds.id join cms_transfermgmt.t_dps_file f on f.inblock=bk.id where f.time_create >= ${START_DATE_S} and f.time_create < ${END_DATE_S} and \$CONDITIONS" \
--fields-terminated-by , --escaped-by \\ --optionally-enclosed-by '\"' \
1>$LOG_FILE.stdout 2>$LOG_FILE.stderr

OUTPUT_ERROR=`cat $LOG_FILE.stderr | egrep "ERROR tool.ImportTool: Error during import: Import job failed!"`
TRANSF_INFO=`cat $LOG_FILE.stderr | egrep "INFO mapreduce.ImportJobBase: Transferred"`

if [[ $OUTPUT_ERROR == *"ERROR"* || ! $TRANSF_INFO == *"INFO"* ]]
then
	echo "Error occured, check $LOG_FILE"
	sendMail $LOG_FILE.stdout cms-transfermgmt-catalog $START_DATE
	sendMail $LOG_FILE.stderr cms-transfermgmt-catalog $START_DATE
else
	hdfs dfs -cat $OUTPUT_FOLDER/part-m-00000 | hdfs dfs -appendToFile - $MERGED_FOLDER/part-m-00000
fi

#hdfs dfs -put /tmp/$me.stdout $OUTPUT_FOLDER/sqoop.stdout && rm /tmp/$me.stdout
#hdfs dfs -put /tmp/$me.stderr $OUTPUT_FOLDER/sqoop.stderr && rm /tmp/$me.stderr
#rm /tmp/$$.stdout /tmp/$$.stderr
