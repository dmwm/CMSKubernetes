FROM golang:latest
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV WDIR=/data
ENV USER=wmarchive
EXPOSE 8200
WORKDIR $WDIR
RUN git clone https://github.com/dmwm/WMArchive.git
RUN mkdir gopath
ENV GOPATH=$WDIR/gopath
RUN go get github.com/go-stomp/stomp && go get github.com/google/uuid
RUN go build WMArchive/src/go/wmarchive.go
