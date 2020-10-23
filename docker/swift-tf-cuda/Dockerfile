FROM nvidia/cuda:10.2-base as nvidia
#FROM ubuntu:latest
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
RUN apt-get update
# configure tzinfo non-interactively
# https://techoverflow.net/2019/05/18/how-to-fix-configuring-tzdata-interactive-input-when-building-docker-images/
RUN DEBIAN_FRONTEND=noninteractive apt install -y tzdata
RUN apt-get install -y curl git libtinfo5 libncurses5 clang-10 libxml2 python libpython3.8 libpython2.7 sudo vim python3-numpy python3-matplotlib
ENV VER=swift-tensorflow-RELEASE-0.11-cuda10.2-cudnn7-ubuntu18.04
ENV WDIR=/
WORKDIR $WDIR
RUN curl -ksLO https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.11/rc2/${VER}.tar.gz
RUN tar xfz ${VER}.tar.gz && rm ${VER}.tar.gz
ENV WDIR=/data
ENV USER=swift
ENV PYTHON_LIBRARY=/usr/lib/python3.6/config-3.6m-x86_64-linux-gnu/libpython3.6.so
WORKDIR $WDIR
RUN git clone https://github.com/vkuznet/SwiftMLExample.git 
RUN mkdir -p $WDIR/tmp && cd $WDIR/tmp && git clone https://github.com/vkuznet/swift-models && cd swift-models && git checkout -b test afc34e82633896d0e482243db732e1e79be6b520
WORKDIR $WDIR/SwiftMLExample
RUN swift build --configuration release
CMD $WDIR/SwiftMLExample/.build/release/swift-ml train -e 300 --batch-size 64 --model-filename model.tf
#CMD nvidia-smi
