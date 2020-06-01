FROM golang:latest as go-builder
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
ARG CGO_ENABLED=0
RUN go build -ldflags="-s -w -extldflags -static" CMSMonitoring/src/go/MONIT/monit.go
RUN go build -ldflags="-s -w -extldflags -static" CMSMonitoring/src/go/MONIT/ssb_alerting.go
RUN go build -ldflags="-s -w -extldflags -static" CMSMonitoring/src/go/MONIT/ggus_parser.go
RUN go build -ldflags="-s -w -extldflags -static" CMSMonitoring/src/go/MONIT/ggus_alerting.go

FROM alpine
RUN mkdir /data
COPY --from=go-builder /data/monit /data
COPY --from=go-builder /data/ssb_alerting /data
COPY --from=go-builder /data/ggus_parser /data
COPY --from=go-builder /data/ggus_alerting /data
COPY --from=go-builder /data/CMSMonitoring/scripts /data
ENV PATH $PATH:/data
