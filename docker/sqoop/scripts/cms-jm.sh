#!/bin/bash
. $(dirname $0)/sqoop_utils.sh
setJava

BASE_PATH=${BASE_PATH:-/project/awg/cms/job-monitoring/avro-snappy}
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
echo "Timerange: $START_DATE to $END_DATE" >> $LOG_FILE.cron
echo "Folder: $OUTPUT_FOLDER" >> $LOG_FILE.cron
echo "quering..." >> $LOG_FILE.cron
#continue

#change to @lcgr-dg-s once it's working
sqoop import -Dmapreduce.job.user.classpath.first=true -Ddfs.client.socket-timeout=120000  --direct --connect $JDBC_URL --fetch-size 10000 --username $USERNAME --password $PASSWORD --target-dir $OUTPUT_FOLDER -m 1 --query \
"select job."\"SchedulerJobId"\", job."\"JobId"\", job."\"JobMonitorId"\", decode(JOB."\"DboardJobEndId"\",'S',(decode(JOB."\"DboardGridEndId"\",'D','success','U','success','failed')),'failed') state, extract( day from ("\"FinishedTimeStamp"\" - "\"StartedRunningTimeStamp"\") )*24*60*60 + extract( hour from ("\"FinishedTimeStamp"\" - "\"StartedRunningTimeStamp"\") )*60*60 + extract( minute from ("\"FinishedTimeStamp"\" - "\"StartedRunningTimeStamp"\") )*60+ extract( second from ("\"FinishedTimeStamp"\" - "\"StartedRunningTimeStamp"\")) as duration, job."\"TaskJobId"\", job."\"LocalBatchJobId"\", job."\"VOJobId"\", job."\"NextJobId"\", job."\"RbId"\", job."\"EventRange"\", job."\"SubNodeIp"\", job."\"LongCEId"\", job."\"ShortCEId"\", job."\"SiteId"\", job."\"WNIp"\" as "\"JobWNIp"\", job."\"DboardGridEndId"\", job."\"DboardStatusEnterTimeStamp"\", job."\"DboardFirstInfoTimeStamp"\", job."\"DboardLatestInfoTimeStamp"\", job."\"GridStatusId"\", job."\"GridStatusReasonId"\", job."\"GridStatusTimeStamp"\", job."\"GridStatusSourceId"\", job."\"GridEndStatusId"\", job."\"GridEndStatusReasonId"\", job."\"GridEndStatusTimeStamp"\", job."\"GridFinishedTimeStamp"\", job."\"ExecutableFinishedTimeStamp"\", job."\"JobExecExitCode"\", job."\"JobExecExitReasonId"\", job."\"JobExecExitTimeStamp"\", job."\"JobApplExitCode"\", job."\"JobApplExitReasonId"\", job."\"CreatedTimeStamp"\", job."\"SubmittedTimeStamp"\", job."\"ScheduledTimeStamp"\", job."\"StartedRunningTimeStamp"\", job."\"FinishedTimeStamp"\", job."\"SchedulerId"\", job."\"JobProcessingDetailsId"\", job."\"SubAttemptStartTimeStamp"\", job."\"SubAttemptCount"\", job."\"UpdateStmtTimeStamp"\", job."\"TimeOutFlag"\", job."\"DboardGridEndStatusReasonId"\", job."\"ExeTime"\", job."\"NEvProc"\" as "\"NEventsProcessed"\", job."\"NEvReq"\", job."\"WrapCPU"\", job."\"WrapWC"\", job."\"ExeCPU"\", job."\"StOutWC"\", job."\"JobType"\" as "\"oldType"\", job."\"StageOutSE"\", job."\"Memory"\", job."\"PilotFlag"\", job."\"InputSE"\", job."\"ParentPilotId"\", job."\"ResubmitterFlag"\", job."\"WNHostName"\", job."\"AccessType"\", job."\"JobLog"\", job."\"TargetCE"\", job."\"CoreCount"\", job."\"NCores"\", job."\"PeakRss"\", task."\"TaskId"\", task."\"TaskMonitorId"\" as "\"TaskName"\", task."\"TaskCreatedTimeStamp"\", task."\"TaskTypeId"\", task."\"NTaskSteps"\", task."\"TaskStatusId"\", task."\"JdlCoreId"\", task."\"NEventsPerJob"\", task."\"ApplicationId"\", task."\"ApplExecId"\", task."\"InputCollectionId"\", task."\"DefaultSchedulerId"\", task."\"SubmissionToolId"\", task."\"SubmissionUIId"\", task."\"JobProcessingTypeId"\", task."\"TargetCE"\" as "\"TaskTargetCE"\", task."\"SubmissionType"\", task."\"SubToolVerId"\", task_type."\"Type"\" as "\"TaskType"\", task_type."\"ValidityFlag"\", task_type."\"GenericType"\", task_type."\"NewGenericType"\" as "\"type"\", task_type."\"NewType"\" as "\"jobtype"\", node."\"IpValue"\" as "\"WNIp"\", users."\"UserId"\", users."\"CertId"\", users."\"RoleId"\", users."\"VOId"\", users."\"UnixName"\", users."\"GridCertificateSubject"\", users."\"GridName"\", users."\"SaveGridName"\", users."\"Country"\" as "\"userCountry"\", site."\"SiteName"\", site."\"DisplayName"\", site."\"SiteState"\", site."\"SiteUniqueId"\", site."\"SiteWWW"\", site."\"SiteEmail"\", site."\"SiteLocation"\", site."\"InteractiveInterfaceFlag"\", site."\"Country"\" as "\"siteCountry"\", site."\"Tier"\", site."\"SamName"\", site."\"VOName"\", site."\"GridMapSize"\", site."\"SiteDBId"\", site."\"CPU"\", site."\"LocalStore"\", site."\"DiskStore"\", site."\"TapeStore"\", site."\"WanStore"\", site."\"NationalBandwidth"\", site."\"OpnBandwidth"\", site."\"JobSlots"\", site."\"LocalMonURL"\", site."\"Federation"\", application."\"ApplicationVersion"\", application."\"Application"\", application."\"ValidityFlag"\" as "\"appValitityFlag"\", submission_tool."\"SubmissionTool"\", scheduler."\"SchedulerName"\", input_collection."\"InputCollection"\", input_collection."\"RequestTimeStamp"\", input_collection."\"ProcessingStartedTimeStamp"\", input_collection."\"MergingStartedTimeStamp"\", input_collection."\"FirstAnalysisAccessTimeStamp"\", input_collection."\"LatestAnalysisAccessTimeStamp"\", input_collection."\"RequestedEvents"\", input_collection."\"ProcessedEvents"\", input_collection."\"MergedEvents"\", input_collection."\"ProdmonDatasetId"\", input_collection."\"Status"\" from CMS_DASHBOARD.job, CMS_DASHBOARD.task, CMS_DASHBOARD.task_type, CMS_DASHBOARD.node,   CMS_DASHBOARD.users, CMS_DASHBOARD.site, CMS_DASHBOARD.input_collection,   CMS_DASHBOARD.application, CMS_DASHBOARD.submission_tool, CMS_DASHBOARD.scheduler where    job."\"TaskId"\" = task."\"TaskId"\"    and task."\"TaskTypeId"\" = task_type."\"TaskTypeId"\"   and task."\"UserId"\" = users."\"UserId"\"    and job."\"SiteId"\" = site."\"SiteId"\"    and job."\"SchedulerId"\" = scheduler."\"SchedulerId"\"   and NODE."\"NodeId"\" = JOB."\"WNIp"\"   and task."\"InputCollectionId"\" = input_collection."\"InputCollectionId"\"   and task."\"SubmissionToolId"\" = submission_tool."\"SubmissionToolId"\"   and task."\"ApplicationId"\" = application."\"ApplicationId"\"    and "\"DboardStatusId"\" = 'T'    and "\"DboardJobEndId"\" in ('S','F')    and "\"FinishedTimeStamp"\" >= to_date('$START_DATE','YYYY-MM-DD')   and "\"FinishedTimeStamp"\" < to_date('$END_DATE','YYYY-MM-DD')   and job."\"TimeOutFlag"\" != 1  and \$CONDITIONS" \
--as-avrodatafile --compression-codec snappy \
1>$LOG_FILE.stdout 2>$LOG_FILE.stderr
#--fields-terminated-by , --escaped-by \\ --optionally-enclosed-by '\"' \

if ! grep 'INFO mapreduce.ImportJobBase: Transferred' $LOG_FILE.stderr 1>/dev/null
then
	echo "Error occured, check $LOG_FILE"
	sendMail $LOG_FILE.stdout atlas-job-monitoring $START_DATE
	sendMail $LOG_FILE.stderr atlas-job-monitoring $START_DATE
fi

#hdfs dfs -put /tmp/$me.stdout $OUTPUT_FOLDER/sqoop.stdout && rm /tmp/$me.stdout
#hdfs dfs -put /tmp/$me.stderr $OUTPUT_FOLDER/sqoop.stderr && rm /tmp/$me.stderr
#rm /tmp/$$.stdout /tmp/$$.stderr
