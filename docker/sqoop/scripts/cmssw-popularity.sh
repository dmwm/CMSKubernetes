#!/bin/bash
. $(dirname $0)/sqoop_utils.sh
setJava

BASE_PATH=${BASE_PATH:-/project/awg/cms/cmssw-popularity/avro-snappy}
JDBC_URL=$(sed '1q;d' cmsr_cstring)
USERNAME=$(sed '2q;d' cmsr_cstring)
PASSWORD=$(sed '3q;d' cmsr_cstring)

me=`basename $0`_$$

if [ -n "$1" ]
then
	START_DATE=$1
else
	START_DATE=`date +'%Y-%m-%d' -d "1 day ago"`
fi

year=`date +'%Y' -d "$START_DATE"`
month=`date +'%-m' -d "$START_DATE"`
day=`date +'%-d' -d "$START_DATE"`
END_DATE=`date +'%Y-%m-%d' -d "$START_DATE + 1 day"`

LOG_FILE=log/`date +'%F_%H%m%S'`_`basename $0`

OUTPUT_FOLDER=$BASE_PATH/year=$year/month=$month/day=$day
echo "Timerange: $START_DATE to $END_DATE" >> $LOG_FILE.cron
echo "Folder: $OUTPUT_FOLDER" >> $LOG_FILE.cron
echo "quering..." >> $LOG_FILE.cron
#continue

#DG (once it's working) cmsr-drac10-scan.cern.ch:10121/CMSR_DRAC10.cern.ch
sqoop import -Dmapreduce.job.user.classpath.first=true -Ddfs.client.socket-timeout=120000 --direct --connect $JDBC_URL --fetch-size 10000 --username $USERNAME --password $PASSWORD --target-dir $OUTPUT_FOLDER -m 1 \
--query "select * from CMS_CMSSW_POPULARITY.T_RAW_CMSSW where END_DATE >= to_date('${START_DATE}','YYYY-MM-DD') and END_DATE < to_date('${END_DATE}','YYYY-MM-DD') and \$CONDITIONS" \
--as-avrodatafile --compression-codec snappy \
1>$LOG_FILE.stdout 2>$LOG_FILE.stderr

if ! grep 'INFO mapreduce.ImportJobBase: Transferred' $LOG_FILE.stderr && ! grep 'Map output records=0' $LOG_FILE.stderr 1>/dev/null
then
	echo "Error occured, check $LOG_FILE"
	sendMail $LOG_FILE.stdout cmssw-popularity $START_DATE
	sendMail $LOG_FILE.stderr cmssw-popularity $START_DATE
fi

#hdfs dfs -put /tmp/$me.stdout $OUTPUT_FOLDER/sqoop.stdout && rm /tmp/$me.stdout
#hdfs dfs -put /tmp/$me.stderr $OUTPUT_FOLDER/sqoop.stderr && rm /tmp/$me.stderr
#rm /tmp/$$.stdout /tmp/$$.stderr
