### cmsmon-hadoop-base

This docker image is created as a base image for cern analytix cluster(`hadoop-analytix`); which includes:

- hadoop
- spark (spark-submit, spark-shell, etc)
- hbase
- sqoop

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
