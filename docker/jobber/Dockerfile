FROM golang:latest
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV WDIR=/data
ENV GOPATH=/data/gopath
RUN mkdir -p $GOPATH
RUN mkdir -p $GOPATH/src/github.com/dshearer
WORKDIR $GOPATH/src/github.com/dshearer
RUN git clone https://github.com/dshearer/jobber.git
WORKDIR $GOPATH/src/github.com/dshearer/jobber
RUN make check
