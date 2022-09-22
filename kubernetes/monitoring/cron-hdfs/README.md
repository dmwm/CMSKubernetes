## CMSSpark/bin cronjobs in k8s 

#### References
* Sourcing cron's environment: https://www.ibm.com/support/pages/aix-cron-cron-environment-and-cron-job-failures
* CronJobs CERN Spark require analytix connection
* Each CronJob requires spark.driver.port and spark.driver.blockManager.port
* services.yaml has to be deployed before any other CronJob
