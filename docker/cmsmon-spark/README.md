## cmsmon-hdfs

Base docker image to run all Hadoop/Spark K8s CronJobs

- Analytix cluster 3.2, spark3 and python3.9 will be used. 
- Base image already contains sqoop.

Installs:

- stomp.py==7.0.0 and creates its zip for spark-submit `--py-files` (spark nodes don't have this version yet)
- Only src/python/CMSMonitoring folder of dmwm/CMSMonitoring repo and creates its zip for spark-submit `--py-files` (WDIR should be in path)
- dmwm/CMSSpark of `CMSSPARK_TAG` build arg and dmwm/CMSMonitoring of `CMSMON_TAG` of build arg
- Other PY modules: click pyspark pandas numpy seaborn matplotlib plotly requests
- amtool

##### Image is built by GH workflow in CMSSpark and CMSMonitoring repository

#### Manual build and push

```shell
# docker image prune -a OR docker system prune -f -a
docker_registry=registry.cern.ch/cmsmonitoring

# For CMSSpark
image_tag=v0.4.1.7
docker build --build-arg CMSSPARK_TAG="image_tag" -t "${docker_registry}/cmsmon-spark:${image_tag}" .

# For CMSMonitoring
image_tag=mon-0.0.1
docker build --build-arg CMSSMON_TAG="image_tag" -t "${docker_registry}/cmsmon-spark:${image_tag}" .

docker push "${docker_registry}/cmsmon-spark:${image_tag}"
```
