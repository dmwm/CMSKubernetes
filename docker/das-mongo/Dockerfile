FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV WDIR=/data
WORKDIR $WDIR

# fetch mongo DB
ENV MONGODBVER=5.0.3
ENV MONGOTOOLS=100.5.1
RUN curl -ksLO https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-debian10-${MONGODBVER}.tgz && curl -ksLO https://fastdl.mongodb.org/tools/db/mongodb-database-tools-debian10-x86_64-${MONGOTOOLS}.tgz
RUN tar xfz mongodb-linux-x86_64-debian10-${MONGODBVER}.tgz && cp mongodb-linux-x86_64-debian10-${MONGODBVER}/bin/[a-z]* /data && rm -rf mongodb-linux-x86_64-debian10-${MONGODBVER}*
RUN tar xfz mongodb-database-tools-debian10-x86_64-${MONGOTOOLS}.tgz && cp mongodb-database-tools-debian10-x86_64-${MONGOTOOLS}/bin/[a-z]* /data && rm -rf mongodb-database-tools-debian10-x86_64-${MONGOTOOLS}*

# build DAS maps tools
RUN git clone https://github.com/dmwm/DASTools
RUN go mod init github.com/dmwm/DASTools && go mod tidy && go get gopkg.in/mgo.v2 && go get gopkg.in/yaml.v2
RUN go build -o das_cleanup -ldflags="-s -w -extldflags -static" DASTools/das_cleanup.go
RUN go build -o dasmaps_parser -ldflags="-s -w -extldflags -static" DASTools/dasmaps_parser.go
RUN go build -o dasmaps_validator -ldflags="-s -w -extldflags -static" DASTools/dasmaps_validator.go
RUN go build -o mongostatus -ldflags="-s -w -extldflags -static" DASTools/mongostatus.go
RUN go build -o mongoimport -ldflags="-s -w -extldflags -static" DASTools/mongoimport.go

FROM debian:stable-slim
RUN apt-get update && apt-get -y install libcurl4 curl
RUN mkdir -p /data
ENV WDIR=/data
WORKDIR $WDIR
COPY --from=go-builder /data/das_cleanup /data/
COPY --from=go-builder /data/dasmaps_parser /data/
COPY --from=go-builder /data/dasmaps_validator /data/
COPY --from=go-builder /data/mongostatus /data/
COPY --from=go-builder /data/mongoimport /data/
COPY --from=go-builder /data/mongo /data/
COPY --from=go-builder /data/mongod /data/
COPY --from=go-builder /data/mongodump /data/
COPY --from=go-builder /data/mongoexport /data/
COPY --from=go-builder /data/mongofiles /data/
COPY --from=go-builder /data/mongos /data/
COPY --from=go-builder /data/mongostat /data/
COPY --from=go-builder /data/mongotop /data/
COPY --from=go-builder /data/DASTools/bin/das_create_json_maps /data/
COPY --from=go-builder /data/DASTools/bin/das_js_fetch /data/
COPY --from=go-builder /data/DASTools/bin/das_js_import /data/
COPY --from=go-builder /data/DASTools/bin/das_js_validate /data/

# setup environment
ENV PATH="/data:${PATH}"
ADD mongodb.conf $WDIR/mongodb.conf
ADD run.sh $WDIR/run.sh
CMD ["./run.sh"]
