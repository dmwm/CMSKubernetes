FROM python:3.8-bullseye
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
RUN apt-get update
RUN apt-get install -y curl libcurl4 libcurl4-openssl-dev python3-pycurl pip apache2-utils
RUN ln -s /usr/bin/python3 /usr/bin/python
ENV TAG=2.1.4rc3
RUN pip install reqmgr2==$TAG
ENV WDIR=/data
ADD run.sh /data/run.sh
WORKDIR $WDIR
CMD ["python3"]
