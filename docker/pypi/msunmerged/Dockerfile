FROM registry.cern.ch/cmsweb/dmwm-base:alma9-py3.12-20250506
LABEL org.opencontainers.image.authors="Alan Malta alan.malta@cern.ch, Dennis Lee dylee@fnal.gov"

# Specific MSUnmerged requirements from epel repository
RUN dnf install epel-release -y && dnf clean all && \
    dnf -y install python3-gfal2-util gfal2-plugin-http gfal2-plugin-dcap gfal2-plugin-file \
                   gfal2-plugin-srm gfal2-plugin-xrootd gfal2-plugin-gridftp gfal2-plugin-sftp && \
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
RUN cat requirements.txt | grep msunmerged | grep -v gfal2 >> req.txt
# Create venv based on environment python,
# install modified requirements,
# and install MSUnmerged itself, without any dependencies
RUN python -m venv .venv && \ 
    .venv/bin/pip install -r req.txt && \
    .venv/bin/pip install --no-deps msunmerged==$TAG

# add venv to the path to use the proper python3
ENV PATH="/data/.venv/bin:$PATH"

# and now setup run.sh and manage scripts accordingly
RUN sed -i -e "s,-config.py,-config-unmerged.py,g" /data/run.sh
RUN sed -i -e "s,config.py,config-unmerged.py,g" /data/manage
ENV USER=_reqmgr2ms
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER ${USER}
RUN sudo chown -R $USER.$USER $WDIR
CMD ["python3"]