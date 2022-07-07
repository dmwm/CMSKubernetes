FROM golang:latest as go-builder
MAINTAINER Ceyhun Uzunoglu ceyhunuzngl@gmail.com

# tag to use
ENV CMSMON_TAG=rgo-0.0.0
ENV WDIR=/data

# build
WORKDIR $GOPATH/src/github.com/dmwm
RUN git clone https://github.com/dmwm/CMSMonitoring.git
WORKDIR $GOPATH/src/github.com/dmwm/CMSMonitoring/src/go/rucio-dataset-mon-go
RUN mkdir -p $WDIR && git checkout tags/$CMSMON_TAG -b build && make && cp -r rucio-dataset-mon-go static $WDIR

FROM gcr.io/distroless/base
COPY --from=go-builder /data /data/
WORKDIR /data
CMD ["/data/rucio-dataset-mon-go"]
