### cmsmon-hadoop-base

This docker image is created as a base image for cern analytix cluster; which includes:

- hadoop
- spark (spark-submit, spark-shell, etc)
- hbase
- sqoop

Since there are different versions of Analytix cluster, this image also has spark2 and spark3 versions

### Attention for `-spark3` image

This docker image uses `python 3.9` as default python executable in `/usr/bin/python`. Because of this fact be careful for:
- You cannot use `yum`, which requires python2, if you use this image as base.
- Your spark job should use python3
- You need to set `PYSPARK_DRIVER_PYTHON` and `PYSPARK_PYTHON` in your Spark jobs. 
  - `PYSPARK_DRIVER_PYTHON` should be set as `/usr/bin/python` which is python3.9
  - `PYSPARK_PYTHON` should be set according to your Spark worker python3.9 path. Recommended to set `/cvmfs` python3.9 path.

#### How to build

Image tag will be changed accordingly cern/cc7-base tag and spark cluster version. For example:

- For spark3: `registry.cern.ch/cmsmonitoring-20220401-1-spark3`
- For spark2: `registry.cern.ch/cmsmonitoring-20220401-1-spark2`

```shell
# Build for spark2: spark 2.4, hadoop 2.7
./build-and-push.sh 2

# Build for spark3: spark 3.3, hadoop 3.2 and with Python 3.9.12
./build-and-push.sh 3 3.9.12
```

- Images will have `spark(2|3)-YYYYMMDD` and `spark(2|3)-latest` tags.
