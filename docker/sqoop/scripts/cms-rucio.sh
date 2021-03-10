#!/bin/bash
. $(dirname $0)/sqoop_utils.sh
setJava

BASE_PATH=${BASE_PATH:-/project/awg/cms/rucio}
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

RUCIO_USERNAME=`cat /etc/secrets/rucio | grep -i username | awk '{split($1,a,"="); print a[1]}'`
RUCIO_PASSWORD=`cat /etc/secrets/rucio | grep -i password | awk '{split($1,a,"="); print a[1]}'`

TZ=UTC sqoop import -Dmapreduce.job.user.classpath.first=true \
-Doraoop.chunk.method=PARTITION -Doraoop.timestamp.string=false \
-Dmapred.child.java.opts="-Djava.security.egd=file:/dev/../dev/urandom" \
--connect jdbc:oracle:thin:@adcr-s.cern.ch:10121/adcr_rucio_2.cern.ch \
--username $RUCIO_USERNAME --password-file $RUCIO_PASSWORD \
--num-mappers 100 --fetch-size 10000 \
--table ATLAS_RUCIO.REPLICAS --as-avrodatafile -z --direct --target-dir \
/user/rucio01/dumps/`date +%Y-%m-%d`/replicas \
1>$LOG_FILE.stdout 2>$LOG_FILE.stderr

OUTPUT_ERROR=`cat $LOG_FILE.stderr | egrep "ERROR tool.ImportTool: Error during import: Import job failed!"`
TRANSF_INFO=`cat $LOG_FILE.stderr | egrep "INFO mapreduce.ImportJobBase: Transferred"`

if [[ $OUTPUT_ERROR == *"ERROR"* || ! $TRANSF_INFO == *"INFO"* ]]
then
	echo "Error occured, check $LOG_FILE"
	sendMail $LOG_FILE.stdout cms-rucio $START_DATE
	sendMail $LOG_FILE.stderr cms-rucio $START_DATE
else
	hdfs dfs -cat $OUTPUT_FOLDER/part-m-00000 | hdfs dfs -appendToFile - $MERGED_FOLDER/part-m-00000
fi
