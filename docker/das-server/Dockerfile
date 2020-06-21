FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV WDIR=/data
WORKDIR $WDIR
RUN mkdir /data/gopath
RUN mkdir /build
ENV GOPATH=/data/gopath
RUN go get github.com/vkuznet/x509proxy
RUN go get github.com/dmwm/cmsauth
RUN go get gopkg.in/mgo.v2
RUN go get github.com/shirou/gopsutil
RUN go get github.com/divan/expvarmon
RUN go get gopkg.in/yaml.v2
RUN git clone https://github.com/dmwm/DASTools
RUN git clone https://github.com/dmwm/das2go
ARG CGO_ENABLED=0
RUN go build -o /build/das2go_monitor -ldflags="-s -w -extldflags -static" /data/das2go/monitor/das2go_monitor.go
WORKDIR /data/das2go
RUN go build -o /build/das2go -ldflags="-s -w -extldflags -static"
RUN cp -r js css images templates /build
RUN curl -ksLO "https://yui.github.io/yui2/archives/yui_2.9.0.zip"
RUN curl -ksLO http://ftp.us.debian.org/debian/pool/main/u/unzip/unzip_6.0-23+deb10u1_amd64.deb
RUN dpkg -i unzip_6.0-23+deb10u1_amd64.deb
RUN unzip -qq -d /build /data/das2go/yui_2.9.0.zip

FROM alpine
RUN mkdir -p /data
COPY --from=go-builder /build/das* /data/
COPY --from=go-builder /build/js /data/js
COPY --from=go-builder /build/css /data/css
COPY --from=go-builder /build/yui /data/yui
COPY --from=go-builder /build/images /data/images
COPY --from=go-builder /build/templates /data/templates
