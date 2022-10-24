FROM python:3.8-bullseye
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
RUN apt-get update
RUN apt-get install -y curl libcurl4 libcurl4-openssl-dev python3-pycurl pip \
    libmariadb-dev-compat libmariadb-dev
RUN ln -s /usr/bin/python3 /usr/bin/python
ENV TAG=2.1.4rc3
RUN pip install wmagent==$TAG
ENV WDIR=/data
WORKDIR $WDIR
CMD ["python3"]