#!/bin/bash

# Set env variables for Spark
export JAVA_HOME=/usr/lib/jvm/jre-1.8.0
export SPARK_HOME=/usr/hdp/spark
export HADOOP_HOME=/usr/hdp/hadoop
export PYTHONPATH=${SPARK_HOME}/python/lib/pyspark.zip:${SPARK_HOME}/python/lib/py4j-*.zip:/usr/lib/python2.7/site-packages
export PATH=$PATH:${SPARK_HOME}/bin

# Add hadoop yarn, hdfs and s3 (share/hadoop/tools/lib) clients
export SPARK_DIST_CLASSPATH=${HADOOP_HOME}/share/hadoop/common/lib/*:${HADOOP_HOME}/share/hadoop/common/*:${HADOOP_HOME}/share/hadoop/hdfs:${HADOOP_HOME}/share/hadoop/hdfs/lib/*:${HADOOP_HOME}/share/hadoop/hdfs/*:${HADOOP_HOME}/share/hadoop/mapreduce/lib/*:${HADOOP_HOME}/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/tools/lib/*
export SPARK_EXTRA_CLASSPATH=$SPARK_DIST_CLASSPATH
