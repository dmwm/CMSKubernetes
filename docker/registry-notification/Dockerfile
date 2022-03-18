FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

#ENV TAG=00.00.01

# build procedure
ENV WDIR=/data
WORKDIR $WDIR
ARG CGO_ENABLED=0
RUN git clone https://github.com/muhammadimranfarooqi/registry-notification
WORKDIR $WDIR/registry-notification
RUN make
# RUN make

FROM alpine:3.15
RUN mkdir -p /data
COPY --from=go-builder /data/registry-notification/registry-notification /data/
CMD ["/data/registry-notification"]
