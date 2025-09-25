FROM golang:1 as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV WDIR=/data
WORKDIR $WDIR

# fetch mongo DB
ENV MONGODBVER=4.4.2
ENV MONGOTOOLS=100.2.1
RUN curl -ksLO https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-debian10-${MONGODBVER}.tgz && curl -ksLO https://fastdl.mongodb.org/tools/db/mongodb-database-tools-debian10-x86_64-${MONGOTOOLS}.tgz
RUN tar xfz mongodb-linux-x86_64-debian10-${MONGODBVER}.tgz && cp mongodb-linux-x86_64-debian10-${MONGODBVER}/bin/[a-z]* /data && rm -rf mongodb-linux-x86_64-debian10-${MONGODBVER}*
RUN tar xfz mongodb-database-tools-debian10-x86_64-${MONGOTOOLS}.tgz && cp mongodb-database-tools-debian10-x86_64-${MONGOTOOLS}/bin/[a-z]* /data && rm -rf mongodb-database-tools-debian10-x86_64-${MONGOTOOLS}*

# setup environment
ENV PATH="/data:${PATH}"
ADD mongodb.conf $WDIR/mongodb.conf
ADD run.sh $WDIR/run.sh
CMD ["./run.sh"]
