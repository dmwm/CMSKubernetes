FROM cern/cc7-base:20220601-1.x86_64 as base_image
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

RUN mkdir -p /data/
ENV PATH $PATH:/data
ENV WDIR=/data
ENV USER=vmbackup
RUN yum install -y jq git make go

WORKDIR $WDIR

RUN git clone https://github.com/VictoriaMetrics/VictoriaMetrics.git && cd VictoriaMetrics && make vmbackup && cd ..
RUN ls -lrt /data
ADD run.sh $WDIR/run.sh

CMD ["crond", "-n", "-s", "&"]
