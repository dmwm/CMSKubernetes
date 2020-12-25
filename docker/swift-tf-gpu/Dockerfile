# get cuda-10
FROM nvidia/cuda:10.1-cudnn8-devel-ubuntu18.04 as cuda-10
# start from cuda-11
FROM nvidia/cuda:11.1-cudnn8-devel-ubuntu18.04
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
COPY --from=cuda-10 /usr/local/cuda-10.1 /usr/local/cuda-10.1
RUN apt-get update
# configure tzinfo non-interactively
# https://techoverflow.net/2019/05/18/how-to-fix-configuring-tzdata-interactive-input-when-building-docker-images/
RUN DEBIAN_FRONTEND=noninteractive apt install -y tzdata
RUN apt-get install -y curl git libtinfo5 libncurses5 clang-10 libxml2 python libpython3.8 libpython2.7 sudo vim python3-numpy python3-matplotlib python3-pip wget
RUN pip3 install --upgrade pip && pip3 install --upgrade tensorflow-gpu && pip3 install torch torchvision
ENV VER=swift-tensorflow-RELEASE-0.12-cuda11.0-cudnn8-ubuntu18.04
ENV WDIR=/
WORKDIR $WDIR
RUN curl -ksLO https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.12/rc2/${VER}.tar.gz
RUN tar xfz ${VER}.tar.gz && rm ${VER}.tar.gz
ENV WDIR=/data
ENV USER=swift
ENV PYTHON_LIBRARY=/usr/lib/python3.8/config-3.8-x86_64-linux-gnu/libpython3.8.so
WORKDIR $WDIR
RUN git clone https://github.com/lgiommi/swift-models.git && cd swift-models && git checkout -b tensorflow-0.11 3bd96d22cca19b1024540815089ac908474df567
RUN git clone https://github.com/lgiommi/Swift4TFBenchmarks.git
RUN cd /data/Swift4TFBenchmarks/models/MNIST/SwiftML && swift build --configuration release
ADD params.json /data/Swift4TFBenchmarks/models/MNIST/params.json
ADD run.sh /data/Swift4TFBenchmarks/models/MNIST/run.sh
