#!/bin/bash
. $(dirname $0)/sqoop_utils.sh
setJava


BASE_PATH=${BASE_PATH:-/project/awg/cms/CMS_ASO/filetransfersdb}
export JDBC_URL=$(sed '1q;d' cmsr_cstring)
export USERNAME=$(sed '2q;d' cmsr_cstring)
export PASSWORD=$(sed '3q;d' cmsr_cstring)

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

sqoop import -Dmapreduce.job.user.classpath.first=true -Ddfs.client.socket-timeout=120000 --direct --connect $JDBC_URL --fetch-size 10000 --username $USERNAME --password $PASSWORD --target-dir $OUTPUT_FOLDER -m 1 --query \
"SELECT * FROM cms_analysis_reqmgr.filetransfersdb F where ( F.tm_last_update >= ${START_DATE_S} ) and ( F.tm_last_update < ${END_DATE_S} ) AND \$CONDITIONS" \
--fields-terminated-by , --escaped-by \\ --optionally-enclosed-by '\"' \
1>$LOG_FILE.stdout 2>$LOG_FILE.stderr

OUTPUT_ERROR=`cat $LOG_FILE.stderr | egrep "ERROR tool.ImportTool: Error during import: Import job failed!"`
TRANSF_INFO=`cat $LOG_FILE.stderr | egrep "INFO mapreduce.ImportJobBase: Transferred"`

if [[ $OUTPUT_ERROR == *"ERROR"* || ! $TRANSF_INFO == *"INFO"* ]]
then
	echo "Error occured, check $LOG_FILE"
	sendMail $LOG_FILE.stdout cms-aso-filetransfersdb $START_DATE
	sendMail $LOG_FILE.stderr cms-aso-filetransfersdb $START_DATE
else
	hdfs dfs -cat $OUTPUT_FOLDER/part-m-00000 | hdfs dfs -appendToFile - $MERGED_FOLDER/part-m-00000
fi

