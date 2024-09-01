FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV WDIR=/data
WORKDIR $WDIR
ARG CGO_ENABLED=0
ENV TAG=v0.1.0
RUN git clone https://github.com/vkuznet/CMSExitCodes.git
WORKDIR $WDIR/CMSExitCodes
RUN git checkout tags/$TAG -b build && make
RUN sed -i -e "s,ROOT,/data/CMSExitCodes,g" /data/CMSExitCodes/server.json

# https://blog.baeke.info/2021/03/28/distroless-or-scratch-for-go-apps/
FROM alpine
# FROM gcr.io/distroless/static AS final
COPY --from=go-builder /data/CMSExitCodes /data/CMSExitCodes
CMD ["/data/CMSExitCodes/CMSExitCodes", "-config", "/data/CMSExitCodes/server.json"]
