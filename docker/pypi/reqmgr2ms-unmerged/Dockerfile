FROM registry.cern.ch/cmsweb/pypi/alma-base:alma9-20240305
MAINTAINER Alan Malta alan.malta@cern.ch

# Specific MSUnmerged requirements from epel repository
RUN dnf install epel-release -y && dnf clean all && \
    dnf -y install python3-gfal2-util && \
    dnf clean all

# Specific run.sh for MSUnmerged
ENV WDIR=/data
WORKDIR $WDIR
ADD run.sh $WDIR/run.sh

# TAG to be passed at build time through `--build-arg TAG=<PYPI_TAG>`. Default: None
ARG TAG=None
# We already installed gfal2 via dnf, so first install only non-gfal2 service dependencies
# FIXME: it is probably best to remove it from the requirements.txt file
RUN curl -ksLO https://raw.githubusercontent.com/dmwm/WMCore/$TAG/requirements.txt
RUN cat requirements.txt | grep dbs3-client > req.txt
RUN cat requirements.txt | grep reqmgr2ms-unmerged | grep -v gfal2 >> req.txt
RUN pip install -r req.txt
# and now install MSUnmerged itself, without any dependencies
RUN pip install --no-deps reqmgr2ms-unmerged==$TAG

# and now setup run.sh and manage scripts accordingly
RUN sed -i -e "s,-config.py,-config-unmerged.py,g" /data/run.sh
RUN sed -i -e "s,config.py,config-unmerged.py,g" /data/manage
ENV USER=_reqmgr2ms
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER ${USER}
RUN sudo chown -R $USER.$USER $WDIR
CMD ["python3"]