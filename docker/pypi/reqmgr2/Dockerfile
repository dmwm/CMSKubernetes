FROM debian:latest
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
RUN apt-get update
RUN apt-get install -y curl libcurl4 libcurl4-openssl-dev python3-pycurl pip
RUN ln -s /usr/bin/python3 /usr/bin/python
RUN pip install reqmgr2
ENV WDIR=/data
WORKDIR $WDIR
CMD ["python3"]
