#!/bin/bash
. $(dirname $0)/sqoop_utils.sh
setJava

BASE_PATH="/project/awg/cms/jm-data-popularity/avro-snappy"
JDBC_URL=$(sed '1q;d' lcgr_cstring)
USERNAME=$(sed '2q;d' lcgr_cstring)
PASSWORD=$(sed '3q;d' lcgr_cstring)

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
hdfs dfs -rm -r -f $OUTPUT_FOLDER
echo "Timerange: $START_DATE to $END_DATE" >> $LOG_FILE.cron
echo "Folder: $OUTPUT_FOLDER" >> $LOG_FILE.cron
echo "quering..." >> $LOG_FILE.cron
#continue

#change to @lcgr-dg-s once it's working
sqoop import -Dmapreduce.job.user.classpath.first=true -Ddfs.client.socket-timeout=120000 --direct --connect $JDBC_URL --fetch-size 10000 --username $USERNAME --password $PASSWORD --target-dir $OUTPUT_FOLDER -m 1 --query \
"select job_file."\"JobId"\", job_file."\"FileName"\", job_file."\"IsParent"\" as "\"IsParentFile"\", job_file."\"ProtocolUsed"\", job_file."\"SuccessFlag"\", job_file."\"FileType"\", job_file."\"LumiRanges"\", job_file."\"StrippedFiles"\", job_block."\"BlockId"\", job_block."\"StrippedBlocks"\", data_block."\"BlockName"\", input_collection."\"InputCollection"\", application."\"Application"\",application."\"ApplicationVersion"\",  task_type."\"Type"\", task_type."\"GenericType"\", task_type."\"NewGenericType"\", task_type."\"NewType"\", task_type."\"ValidityFlag"\", submission_tool."\"SubmissionTool"\", job."\"InputSE"\", job."\"TargetCE"\", site."\"VOName"\" as "\"SiteName"\", scheduler."\"SchedulerName"\", job."\"JobMonitorId"\", job."\"TaskJobId"\", job."\"SchedulerJobId"\" as "\"SchedulerJobIdV2"\",  task."\"TaskId"\", task."\"TaskMonitorId"\",  task."\"NEventsPerJob"\", task."\"NTaskSteps"\",  job."\"JobExecExitCode"\", job."\"JobExecExitTimeStamp"\", job."\"StartedRunningTimeStamp"\", job."\"FinishedTimeStamp"\", job."\"WrapWC"\", job."\"WrapCPU"\", job."\"ExeCPU"\", job."\"NCores"\", job."\"NEvProc"\", job."\"NEvReq"\", job."\"WNHostName"\",job."\"JobType"\", users."\"UserId"\", users."\"GridName"\" from CMS_DASHBOARD.job, CMS_DASHBOARD.job_file, CMS_DASHBOARD.job_block, CMS_DASHBOARD.data_block, CMS_DASHBOARD.input_collection, CMS_DASHBOARD.application, CMS_DASHBOARD.task_type, CMS_DASHBOARD.submission_tool, CMS_DASHBOARD.task, CMS_DASHBOARD.site, CMS_DASHBOARD.scheduler, CMS_DASHBOARD.users where job."\"TaskId"\" = task."\"TaskId"\" and task."\"TaskTypeId"\" = task_type."\"TaskTypeId"\" and TASK."\"InputCollectionId"\" = input_collection."\"InputCollectionId"\" and job."\"SiteId"\" = site."\"SiteId"\" and job."\"SchedulerId"\" = scheduler."\"SchedulerId"\" and task."\"UserId"\" = users."\"UserId"\" and task."\"SubmissionToolId"\" = submission_tool."\"SubmissionToolId"\" and task."\"ApplicationId"\" = application."\"ApplicationId"\" and job."\"JobId"\" = job_block."\"JobId"\" and job_block."\"BlockId"\" = data_block."\"BlockId"\" and job."\"JobId"\" = job_file."\"JobId"\" and "\"FinishedTimeStamp"\" >= to_date('$START_DATE','YYYY-MM-DD') and "\"FinishedTimeStamp"\" < to_date('$END_DATE','YYYY-MM-DD') and \$CONDITIONS order by job_block."\"JobId"\"" \
--as-avrodatafile --compression-codec snappy \
1>$LOG_FILE.stdout 2>$LOG_FILE.stderr
#--fields-terminated-by , --escaped-by \\ --optionally-enclosed-by '\"' \

OUTPUT_ERROR=`cat $LOG_FILE.stderr | egrep "ERROR tool.ImportTool: Error during import: Import job failed!"`
TRANSF_INFO=`cat $LOG_FILE.stderr | egrep "INFO mapreduce.ImportJobBase: Transferred"`

if [[ $OUTPUT_ERROR == *"ERROR"* || ! $TRANSF_INFO == *"INFO"* ]]
then
	echo "Error occured, check $LOG_FILE"
	sendMail $LOG_FILE.stdout cms-popularity $START_DATE
	sendMail $LOG_FILE.stderr cms-popularity $START_DATE
fi

#hdfs dfs -put /tmp/$me.stdout $OUTPUT_FOLDER/sqoop.stdout && rm /tmp/$me.stdout
#hdfs dfs -put /tmp/$me.stderr $OUTPUT_FOLDER/sqoop.stderr && rm /tmp/$me.stderr
#rm /tmp/$$.stdout /tmp/$$.stderr
