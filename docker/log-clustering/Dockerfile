FROM cern/cc7-base:20200504-1.x86_64
#FROM cmssw/cmsweb
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ADD hadoop.repo /etc/yum.repos.d/hadoop.repo
# ADD slc7-cernonly.repo /etc/yum.repos.d/slc7-cernonly.repo
# ADD RPM-GPG-KEY-wlcg /etc/pki/rpm-gpg/RPM-GPG-KEY-wlcg

# hadoop related RPMs
RUN yum install -y cern-hadoop-config spark-bin-2.3.0 hadoop-bin-2.7.5 hbase-bin-1.2.6 sqoop-bin-1.4 \
    java-1.8.0-openjdk-devel python27-python-pip python36-pip python36-devel gcc git golang
RUN yum clean all

# replace python2 with python3
RUN rm /usr/bin/python
RUN ln -s /usr/bin/python3 /usr/bin/python

# setup proper environment
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
RUN git clone https://github.com/dmwm/CMSMonitoring.git
RUN go get github.com/go-stomp/stomp
RUN cp CMSMonitoring/src/go/MONIT/monit.go .
RUN go build monit.go
RUN cp monit $WDIR

# install log-clustering and required dependencies
WORKDIR $WDIR
RUN git clone https://github.com/vkuznet/log-clustering.git
RUN pip-3 install Cython
RUN pip-3 install -r log-clustering/workflow/requirements.txt
RUN python3 -c "import nltk; nltk.download('stopwords')"

# add crons
ADD cronjobs.txt $WDIR
ADD hadoop-env.sh $WDIR
RUN crontab cronjobs.txt
