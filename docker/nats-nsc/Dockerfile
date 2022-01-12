FROM golang:1
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV WDIR=/data
WORKDIR $WDIR
# build and run nats-account-server
RUN go get github.com/nats-io/nsc
RUN go get github.com/nats-io/nats-account-server
ADD run.sh $WDIR/run.sh
CMD ["./run.sh"]
