FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# DAS tag to use
ENV TAG=00.00.17

# build procedure
ENV WDIR=/data
WORKDIR $WDIR
ARG CGO_ENABLED=0
RUN git clone https://github.com/vkuznet/httpgo
WORKDIR $WDIR/httpgo
RUN git checkout tags/$TAG -b build && make
# RUN make

FROM alpine:3.16
RUN mkdir -p /data
COPY --from=go-builder /data/httpgo/httpgo /data/
CMD ["/data/httpgo"]
