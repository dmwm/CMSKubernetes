FROM golang:1.20 AS build
LABEL maintainer="Nikodemas Tuckus <tuckus.nikodemas@cern.ch>"

ARG TAG=v00.00.00
ENV WDIR=/data \
    CGO_ENABLED=0

WORKDIR $WDIR

RUN git clone https://github.com/dmwm/udp-collector && \
    cd udp-collector && \
    if [ "$TAG" = "v00.00.00" ]; then git checkout master; else git checkout tags/$TAG -b build; fi && \
    make

#FROM alpine:3.14
FROM gcr.io/distroless/base AS final
LABEL maintainer="Nikodemas Tuckus <tuckus.nikodemas@cern.ch>"

ENV WDIR=/data
WORKDIR $WDIR
EXPOSE 9331
EXPOSE 9330

COPY --from=build /data/udp-collector/udp_collector /data/udp_collector