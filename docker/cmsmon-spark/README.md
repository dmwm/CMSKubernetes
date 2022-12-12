## cmsmon-hdfs

Base docker image to run all Hadoop/Spark K8s CronJobs

- Analytix cluster 3.2, spark3 and python3.9 will be used. 
- Base image already contains sqoop.

Installs:

- stomp.py==7.0.0 and creates its zip for spark-submit `--py-files` (spark nodes don't have this version yet)
- Only src/python/CMSMonitoring folder of dmwm/CMSMonitoring repo and creates its zip for spark-submit `--py-files` (WDIR should be in path)
- dmwm/CMSSpark
- Other PY modules: click pyspark pandas numpy seaborn matplotlib plotly

##### Image is built by GH workflow in CMSSpark repository

#### Manual build and push

```shell
# docker image prune -a OR docker system prune -f -a
docker_registry=registry.cern.ch/cmsmonitoring
image_tag=v0.0.0.test
docker build -t "${docker_registry}/cmsmon-spark:${image_tag}" .
docker push "${docker_registry}/cmsmon-spark:${image_tag}"
```
