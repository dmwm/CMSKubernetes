FROM cern/cc7-base:20210501-2.x86_64 as base_image
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

RUN mkdir -p /data/
ENV PATH $PATH:/data
ENV TAG=v00.00.04
ENV WDIR=/data
ENV USER=vmbackup
RUN yum install -y jq git make go

WORKDIR $WDIR

RUN git clone https://github.com/VictoriaMetrics/VictoriaMetrics.git && cd VictoriaMetrics && make vmbackup && cd ..
RUN echo "0 * * * * /data/run.sh" >> /tmp/mycron
RUN crontab /tmp/mycron
RUN ls -lrt /data
ADD run.sh $WDIR/run.sh

CMD ["./run.sh"]
