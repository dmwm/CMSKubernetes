# Celery Flower Useful Commands

* `k exec --stdin --tty spider-worker-* -n spider -- /bin/bash`
* `/usr/bin/python3 /usr/local/bin/celery -A htcondor_es.celery.celery inspect stats --timeout 5`
* `celery -A proj control enable_events`
* `celery -A proj events --dump`
* `celery -A proj events`
* `celery -A proj control disable_events`


###### Chech task status from flower: 
http://htcondor-spider-wn62sg32fmxi-node-1.cern.ch:31111/task/7a95528f-719e-437c-bf4f-2a3f208c3564
> Started and Succeeded time difference should not be greater than 12m!

