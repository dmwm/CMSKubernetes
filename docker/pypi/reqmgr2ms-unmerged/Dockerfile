FROM registry.cern.ch/cmsweb/gfal:latest as gfal
FROM python:3.8-bullseye
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
RUN apt-get update
RUN apt-get install -y curl libcurl4 libcurl4-openssl-dev python3-pycurl pip
RUN ln -s /usr/bin/python3 /usr/bin/python
COPY --from=gfal /data/miniconda /data/miniconda
ENV WDIR=/data
ENV PATH $PATH:$WDIR/miniconda/bin
ENV PYTHONPATH $WDIR/miniconda/lib/python3.8/site-packages/
ENV TAG=2.1.4rc3
ENV REQTAG=2.1.4.pre3
WORKDIR $WDIR
# since we install gfal via external image we'll skip it for installation
# of reqmgr2ms-unmerged, but to satisfy dependencies we'll install them first
RUN curl -ksLO https://raw.githubusercontent.com/dmwm/WMCore/$REQTAG/requirements.txt
RUN cat requirements.txt | grep -v gfal2 > req.txt
RUN pip install -r req.txt
RUN pip install --no-deps reqmgr2ms-unmerged==$TAG
CMD ["python3"]
