FROM ubuntu:20.04
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
RUN apt-get update
# configure tzinfo non-interactively
# https://techoverflow.net/2019/05/18/how-to-fix-configuring-tzdata-interactive-input-when-building-docker-images/
RUN DEBIAN_FRONTEND=noninteractive apt install -y tzdata
RUN apt-get install -y curl git libtinfo5 libncurses5 clang-10 libxml2 python libpython3.8 libpython2.7 sudo vim python3-numpy python3-matplotlib
ENV VER=swift-tensorflow-RELEASE-0.11-ubuntu18.04
ENV WDIR=/
WORKDIR $WDIR
RUN curl -ksLO https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.11/rc2/${VER}.tar.gz
RUN tar xfz ${VER}.tar.gz && rm ${VER}.tar.gz
ENV WDIR=/data
ENV USER=swift
ENV PYTHON_LIBRARY=/usr/lib/python3.8/config-3.8-x86_64-linux-gnu/libpython3.8.so
WORKDIR $WDIR
# add new user
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
# add user to sudoers file
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# switch to user
USER ${USER}
RUN git clone https://github.com/vkuznet/SwiftMLExample.git
