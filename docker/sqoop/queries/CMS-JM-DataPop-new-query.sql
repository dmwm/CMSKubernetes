select 
 job_file."JobId", 
 job_file."FileName",
 job_file."IsParent" as "IsParentFile",
 job_file."ProtocolUsed",
 job_file."SuccessFlag",
 job_file."FileType",
 job_file."LumiRanges",
 job_file."StrippedFiles",

 job_block."BlockId",
 job_block."StrippedBlocks",
 data_block."BlockName",
 input_collection."InputCollection",
 application."Application",
 task_type."Type",
 submission_tool."SubmissionTool",
 job."InputSE",
 job."TargetCE",
 site."VOName" as "SiteName",
 scheduler."SchedulerName",

 job."JobMonitorId",
 job."TaskJobId",
 job."SchedulerJobId" as "SchedulerJobIdV2", 
 task."TaskId",
 task."TaskMonitorId",
 job."JobExecExitCode",
 job."JobExecExitTimeStamp",
 job."StartedRunningTimeStamp",
 job."FinishedTimeStamp",
 job."WrapWC",
 job."WrapCPU",
 job."ExeCPU",
 users."UserId",
 users."GridName"

 from CMS_DASHBOARD.job,
 CMS_DASHBOARD.job_file,
 CMS_DASHBOARD.job_block,
 CMS_DASHBOARD.data_block,
 CMS_DASHBOARD.input_collection,
 CMS_DASHBOARD.application,
 CMS_DASHBOARD.task_type,
 CMS_DASHBOARD.submission_tool,
 CMS_DASHBOARD.task,
 CMS_DASHBOARD.site,
 CMS_DASHBOARD.scheduler,
 CMS_DASHBOARD.users

where 
 job."TaskId" = task."TaskId" and
 task."TaskTypeId" = task_type."TaskTypeId" and
 TASK."InputCollectionId" = input_collection."InputCollectionId" and
 job."SiteId" = site."SiteId" and
 job."SchedulerId" = scheduler."SchedulerId" and
 task."UserId" = users."UserId" and
 task."SubmissionToolId" = submission_tool."SubmissionToolId" and
 task."ApplicationId" = application."ApplicationId" and
 job."JobId" = job_block."JobId" and
 job_block."BlockId" = data_block."BlockId" and
 job."JobId" = job_file."JobId" and
 job."FinishedTimeStamp" >= to_date(:startdate,'YY-MM-DD HH24:MI:SS') and
 job."FinishedTimeStamp" < to_date(:enddate,'YY-MM-DD HH24:MI:SS')

order by job_block."JobId" 
