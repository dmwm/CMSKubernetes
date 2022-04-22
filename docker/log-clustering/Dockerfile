FROM registry.cern.ch/cmsmonitoring/cmsmon-hadoop-base:20220401-1-spark2
#FROM cmssw/cmsweb
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

WORKDIR /
# hadoop related RPMs
RUN yum install -y python3 gcc golang && python3 -m pip install --upgrade pip
RUN yum clean all &&  rm -rf /var/cache/yum

# replace python2 with python3
RUN rm /usr/bin/python
RUN ln -s /usr/bin/python3 /usr/bin/python

# setup proper environment

ENV HADOOP_CONF_DIR=/etc/hadoop/conf
ENV PATH $PATH:/usr/hdp/hadoop/bin:/usr/hdp/sqoop/bin:/usr/hdp/spark/bin
RUN hadoop-set-default-conf.sh analytix
RUN source hadoop-setconf.sh analytix

# setup necessary environment
ENV WDIR=/data
ENV PATH="${PATH}:${WDIR}:${WDIR}/log-clustering:${WDIR}/log-clustering/workflow"
ENV PYTHONPATH="/usr/local/lib64/python3.6/site-packages:${WDIR}/log-clustering/workflow"

# build Go monit tool
ENV GOPATH=$WDIR/gopath
RUN mkdir -p $GOPATH
ENV PATH="${PATH}:${GOROOT}/bin:${WDIR}"
WORKDIR /
RUN git clone https://github.com/dmwm/CMSMonitoring.git
RUN cp CMSMonitoring/src/go/MONIT/monit.go .
RUN go mod init monit.go
RUN go get github.com/go-stomp/stomp
RUN go build monit.go
RUN cp monit $WDIR

# install log-clustering and required dependencies
WORKDIR $WDIR
RUN git clone https://github.com/vkuznet/log-clustering.git
RUN pip3 install Cython
RUN pip3 install -r log-clustering/workflow/requirements.txt
RUN python3 -c "import nltk; nltk.download('stopwords')"

# add crons
ADD cronjobs.txt $WDIR
ADD hadoop-env.sh $WDIR
RUN crontab cronjobs.txt
