This Helm chart provides all-in-one template for CMSSpark cronjobs. 

### Notes
Go template language provides a range block, which is actively used in this template. It allows `values.yaml` to have a dictionary containing multiple cronjob configurations. <br> Provided key naming has to be followed, e.g. "0", "1", "2" ... These keys are used as indexes to increment NodePorts of each CronJob service.

Each CronJob runs a bash script specified in *command* field. Arguments have to be provided as a YAML multiline string. Both fields are then concatenated with common cronjob arguments in _helpers.tpl and included as a complete argument for the `/bin/bash -c` in CronJob.

Depending on the `test.enabled` parameter value, `cronjob.yaml` or `test-job.yaml` will be deployed. **Output directories for testing have to be provided individually.** **Some cronjobs don't support --test flag.**

Some CronJobs may need EOS access. This can be specified with `eosEnabled: true` individually in the same field as `name` and `schedule`.


### Testing 
If `test.enabled` parameter is set to true, `--test` flag will be added as an argument for each CronJob. Moreover, each CronJob will be deployed as a Job and executed right after deployment without waiting for the schedule time to be reached. 

Following command can be used to deploy in test mode using `--set`

```
helm install cmsmon-cron cmsmon-cron/ --set test.enabled=true --debug
```

### TODO
- [ ] Migrate Google's [spark-on-k8s-operator](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator)
- [ ] Convert to Ingress
- [ ] Utilize Chart in FluxCD pipeline