## CRAB LOGSTASH

Used for parsing CRAB Taskworker VM instance logs. Filebeat should send data with `crabtaskworker` tag.

- Refs: https://monit-docs.web.cern.ch/metrics/http/
- https://its.cern.ch/jira/browse/CMSMONIT-460

#### Resorved keywords

They are used in grok parsers (alpha order) !!please update the list when you update the grok!!

```
- acquiredFiles, acquiredFilesStatus, action,
- blocks,
- completionTime,
- exceptionHandled,
- files, filesPublished, functionName,
- logMsg, log_type,
- publicationResult, publisher_json_data,
- slaveID,
- taskID, taskName, timestamp_temp, tw_json_data,
- Worker, workType,
```

#### Example log lines for grok

There are currently 10 different grok definitions. Example log lines for each **log_type**:

- `work_on_task_completed`
    - `2020-10-21 00:11:41,973:DEBUG:Worker,111:Process-6: KILL work on 201020_214355:mimacken_crab_2017_LFVAnalysis_SingleEle_F completed in 2 seconds: Status: OK`
- `publisher_config_data`
    - `2021-05-19 09:15:34,006:INFO:PublisherMaster,149:PUBSTART: {"max_slaves": 5, "dryRun": false, "asoworker": "schedd", "DBShost": "cmsweb-prod.cern.ch", "instance": "test2", "version": "v3.210514"}`
- `tw_config_data`
    - `2021-05-25 18:50:55,460:INFO:MasterWorker,174:TWSTART: {"restHost": "X", "name": "Y", "recurringActions": ["RemovetmpDir", "BanDestinationSites", "TapeRecallStatus"], "DBSHostName": "Z", "instance": "other", "version": "development", "dbInstance": "dev", "nslaves": 1}`
- `start_new_task`
    - `2020-09-10 04:56:49,748:DEBUG:Worker,104:Process-6: Starting <function handleResubmit at 0x7f65ea4b5b90> on 200901_130305:wjang_crab_NanoAODv7_v0_QCD_HT2000toInf_TuneCUETP8M1_13TeV-madgraphMLM-pythia8`
- `failed_publication`
    - `2020-11-21 01:45:32,789:ERROR:PublisherMaster,550:Taskname 201118_182833:vcepaiti_crab_QCD_Pt-80to120_EMEnriched_TuneCUETP8M1_13TeV_pythia8-2016_NANOX_201117 : 1 blocks failed for a total of 11 files`
- `successful_publication`
    - `2020-11-27 14:25:16,191:INFO:PublisherMaster,545:Taskname 201127_011713:anstahll_crab_AODSkim_HIMinimumBias14_HIRun2018_04Apr2019_DiMuMassMin2_20201117 is OK. Published 37 files in 1 blocks.`
- `publication_error`
    - `2020-11-26 19:23:27,737:ERROR:PublisherMaster,554:Exception when calling TaskPublish!`
- `acquired_files`
    - `2021-04-15 22:23:39,566:DEBUG:master:          8 : 210415_093249:algomez_crab_QCDHT100to200TuneCP5PSWeights13TeV-madgraphMLM`
- `acquired_files_status`
    - `2021-12-03 20:13:59,965:DEBUG:PublisherMaster,413:acquired_files:   OK    89 : 211203_174945:cmsbot_crab_20211203_184942`
- `action_on_task_finished`
    - `2020-09-10 04:48:50,091:INFO:Handler,104:Finished <TaskWorker.Actions.MyProxyLogon.MyProxyLogon object at 0x7f65e821a610> on 200901_125412:wjang_crab_NanoAODv7_v0_QCD_HT700to1000_TuneCUETP8M1_13TeV-madgraphMLM-pythia8 in 1 seconds`


#### Notes

Tested with current filebeat version in VM: 7.10.0
