FROM golang:1.17.0-bullseye as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV WDIR=/data
WORKDIR $WDIR

# fetch mongo DB
ENV MONGODBVER=4.4.2
ENV MONGOTOOLS=100.2.1
RUN curl -ksLO https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-debian10-${MONGODBVER}.tgz && curl -ksLO https://fastdl.mongodb.org/tools/db/mongodb-database-tools-debian10-x86_64-${MONGOTOOLS}.tgz
RUN tar xfz mongodb-linux-x86_64-debian10-${MONGODBVER}.tgz && cp mongodb-linux-x86_64-debian10-${MONGODBVER}/bin/[a-z]* /data && rm -rf mongodb-linux-x86_64-debian10-${MONGODBVER}*
RUN tar xfz mongodb-database-tools-debian10-x86_64-${MONGOTOOLS}.tgz && cp mongodb-database-tools-debian10-x86_64-${MONGOTOOLS}/bin/[a-z]* /data && rm -rf mongodb-database-tools-debian10-x86_64-${MONGOTOOLS}*

# build DAS maps tools
RUN go get gopkg.in/yaml.v2
RUN go get gopkg.in/mgo.v2
RUN git clone https://github.com/dmwm/DASTools
RUN go build -o das_cleanup -ldflags="-s -w -extldflags -static" DASTools/das_cleanup.go
RUN go build -o dasmaps_parser -ldflags="-s -w -extldflags -static" DASTools/dasmaps_parser.go
RUN go build -o dasmaps_validator -ldflags="-s -w -extldflags -static" DASTools/dasmaps_validator.go
RUN go build -o mongostatus -ldflags="-s -w -extldflags -static" DASTools/mongostatus.go
RUN go build -o mongoimport -ldflags="-s -w -extldflags -static" DASTools/mongoimport.go

# setup environment
ENV PATH="/data:/data/DASTools/bin:${PATH}"
ADD mongodb.conf $WDIR/mongodb.conf
ADD run.sh $WDIR/run.sh
CMD ["./run.sh"]
