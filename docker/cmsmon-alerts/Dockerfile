FROM golang:latest
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
#RUN apt-get update && apt-get -y install cron
ENV WDIR=/data
WORKDIR $WDIR
ENV PATH $PATH:$WDIR:$WDIR/CMSMonitoring/scripts
RUN mkdir gopath
ENV GOPATH $WDIR/gopath
RUN go get github.com/go-stomp/stomp
RUN go get github.com/vkuznet/x509proxy
RUN git clone https://github.com/dmwm/CMSMonitoring.git
RUN go build CMSMonitoring/src/go/MONIT/monit.go
RUN go build CMSMonitoring/src/go/MONIT/ssb_alerting.go
RUN go build CMSMonitoring/src/go/MONIT/ggus_parser.go
RUN go build CMSMonitoring/src/go/MONIT/ggus_alerting.go
