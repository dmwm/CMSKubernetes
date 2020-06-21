FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV WDIR=/data
WORKDIR $WDIR

# fetch mongo DB
RUN curl -ksLO https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-debian10-4.2.8.tgz
RUN tar xfz mongodb-linux-x86_64-debian10-4.2.8.tgz
RUN cp mongodb-linux-x86_64-debian10-4.2.8/bin/* /data
RUN rm -rf mongodb-linux-x86_64-debian10-4.2.8*

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
