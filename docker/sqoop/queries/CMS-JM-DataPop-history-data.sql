select
	JOBID as "SchedulerJobId", 
	FILENAME as "FileName",
	ISPARENT as "IsParentFile",
	PROTOCOL as "ProtocolUsed",
	FILEEXITFLAG as "SuccessFlag",
	FILETYPE as "FileType",
	LUMIRANGE as "LumiRanges",
	STRIPPEDFILES as "StrippedFiles",

	BLOCKID as "BlockId",
	STRIPPEDBLOCKS as "StrippedBlocks",
	BLOCKNAME as "BlockName",
	INPUTCOLLECTION as "InputCollection",
	APPLICATION as "Application",
	TASKTYPE as "Type",
	SUBMISSIONTOOL as "SubmissionTool",
	INPUTSE as "InputSE",
	TARGETCE as "TargetCE",
	SITENAME as "SiteName",
	SCHEDULERNAME as "SchedulerName",

	JOBMONITORID as "JobMonitorId",
	TASKJOBID as "TaskJobId",
	TASKID as "TaskId",
	TASKMONITORID as "TaskMonitorId",
	JOBEXECEXITCODE as "JobExecExitCode",
	JOBEXECEXITTIMESTAMP as "JobExecExitTimeStamp",
	STARTEDRUNNINGTIMESTAMP as "StartedRunningTimeStamp",
	FINISHEDTIMESTAMP as "FinishedTimeStamp",
	WALLCLOCKCPUTIME as "WrapWC",
	CPUTIME as "WrapCPU",
	Null as "ExeCPU",
	USERID as "UserId",
	USERNAME as "GridName"

from
	CMS_POPULARITY_SYSTEM.RAW_FILE
where
	RAW_FILE."FINISHEDTIMESTAMP" >= to_date(:startdate,'YY-MM-DD HH24:MI:SS') and 
	RAW_FILE."FINISHEDTIMESTAMP" < to_date(:enddate,'YY-MM-DD HH24:MI:SS')
