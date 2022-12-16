FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
WORKDIR $WDIR

RUN git clone https://github.com/dmwm/CMSMonitoring.git
ARG CGO_ENABLED=0
WORKDIR $WDIR/CMSMonitoring/src/go/MONIT
RUN go build -ldflags="-s -w -extldflags -static" monit.go && cp monit $WDIR

FROM registry.cern.ch/cmsmonitoring/cmsmon-hadoop-base:spark3-latest
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
WORKDIR $WDIR
ENV PATH="${PATH}:${WDIR}:${WDIR}/log-clustering:${WDIR}/log-clustering/workflow"
COPY --from=go-builder /data $WDIR

RUN python3 -m pip install --upgrade pip &&  \
    rm /usr/bin/python && rm /usr/bin/pip && \
    ln -s /usr/bin/python3 /usr/bin/python && ln -s /usr/bin/pip3 /usr/bin/pip && \
    git clone https://github.com/vkuznet/log-clustering.git && \
    pip install -r log-clustering/workflow/requirements.txt && \
    python -c "import nltk; nltk.download('stopwords')"

# Run crond
CMD ["crond", "-n", "-s", "&"]
