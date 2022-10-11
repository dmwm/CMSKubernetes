FROM python:3.8-bullseye
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
RUN apt-get update
RUN apt-get install -y curl libcurl4 libcurl4-openssl-dev python3-pycurl pip
RUN ln -s /usr/bin/python3 /usr/bin/python
RUN pip install reqmgr2ms-output
ENV WDIR=/data
WORKDIR $WDIR
#ADD deploy-centralvenv.sh /data/deploy-centralvenv.sh
#RUN apt-get install -y git tree python3-venv
#RUN /data/deploy-centralvenv.sh -l reqmgr2ms-output==2.1.4rc3 -d /data/tmp/WMCore.venv333/ -y
CMD ["python3"]
