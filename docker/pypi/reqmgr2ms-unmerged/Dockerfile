FROM registry.cern.ch/cmsweb/gfal:latest as gfal
FROM registry.cern.ch/cmsweb/dmwm-base:pypi-20240923-stable
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
COPY --from=gfal /data/miniconda /data/miniconda
ENV WDIR=/data
ENV PATH $PATH:$WDIR/miniconda/bin
ENV PYTHONPATH $WDIR/miniconda/lib/python3.8/site-packages/
# TAG to be passed at build time through `--build-arg TAG=<PYPI_TAG>`. Default: None
ARG TAG=None
WORKDIR $WDIR
ADD run.sh $WDIR/run.sh
# since we install gfal via external image we'll skip it for installation
# of reqmgr2ms-unmerged, but to satisfy dependencies we'll install them first
RUN curl -ksLO https://raw.githubusercontent.com/dmwm/WMCore/$TAG/requirements.txt
RUN cat requirements.txt | grep -v gfal2 > req.txt
RUN pip install -r req.txt
RUN pip install --no-deps reqmgr2ms-unmerged==$TAG 
RUN sed -i -e "s,-config.py,-config-unmerged.py,g" /data/run.sh
RUN sed -i -e "s,config.py,config-unmerged.py,g" /data/manage
ENV WDIR=/data
ENV USER=_reqmgr2ms
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER ${USER}
RUN sudo chown -R $USER.$USER $WDIR
CMD ["python3"]
