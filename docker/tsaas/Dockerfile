FROM debian
#FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

RUN apt-get update && \
    apt-get install -y ca-certificates unzip curl pip vim less \
    git default-jre default-jdk && \
    apt-get clean && \
    rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /data
ENV TZIP=libtorch-shared-with-deps-latest.zip
ENV TURL=https://download.pytorch.org/libtorch/nightly/cpu/libtorch-shared-with-deps-latest.zip
RUN cd /opt/ && \
    curl -ksLO $TURL && \
    unzip $TZIP && rm $TZIP

RUN echo "$PYTORCH_DIST_DIR/lib" >> /etc/ld.so.conf.d/libtorch.conf && ldconfig
ENV LD_LIBRARY_PATH /opt/libtorch/lib:${LD_LIBRARY_PATH}

RUN pip install torchserve torch-model-archiver torch-workflow-archiver
RUN pip install -U grpcio protobuf grpcio-tools
RUN pip install torch torchvision captum
RUN mkdir torchserve && cd torchserve && \
    mkdir model_store && \
    git clone https://github.com/pytorch/serve.git
WORKDIR /data/torchserve
ADD run.sh /data/torchserve/run.sh
CMD ["/data/torchserve/run.sh"]
