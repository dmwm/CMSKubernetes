FROM cmssw/cmsweb
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# hadoop related RPMs
RUN yum install -y cern-hadoop-config spark-bin-2.3.0 hadoop-bin-2.7.5 hbase-bin-1.2.6 sqoop-bin-1.4 \
    java-1.8.0-openjdk-devel python27-python-pip python36-pip python36-devel gcc

# setup proper environment
ENV PATH $PATH:/usr/hdp/hadoop/bin:/usr/hdp/sqoop/bin:/usr/hdp/spark/bin
RUN hadoop-set-default-conf.sh analytix
RUN source hadoop-setconf.sh analytix

# setup necessary environment
ENV WDIR=/data
ENV PATH="${PATH}:${WDIR}:${WDIR}/log-clustering:${WDIR}/log-clustering/workflow"
ENV PYTHONPATH="${WDIR}/log-clustering/workflow"

# install log-clustering and required dependencies
WORKDIR $WDIR
RUN pip install --upgrade pip
RUN git clone https://github.com/vkuznet/log-clustering.git
RUN pip-3 install Cython
RUN pip-3 install -r log-clustering/workflow/requirements.txt

# add crons
ADD cronjobs.txt $WDIR
RUN crontab cronjobs.txt
