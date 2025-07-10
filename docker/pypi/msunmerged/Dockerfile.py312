FROM registry.cern.ch/cmsweb/gfal:alma9-py3.12-1.13.0 AS gfal2
FROM registry.cern.ch/cmsweb/dmwm-base:alma9-py3.12-20250529
LABEL org.opencontainers.image.authors="Alan Malta alan.malta@cern.ch, Dennis Lee dylee@fnal.gov"

# Specific MSUnmerged requirements from epel repository
RUN dnf install epel-release -y && dnf clean all && \
    dnf -y install patch gfal2 python3-gfal2-util gfal2-plugin-http gfal2-plugin-dcap gfal2-plugin-file \
                   gfal2-plugin-srm gfal2-plugin-xrootd gfal2-plugin-gridftp gfal2-plugin-sftp && \
    dnf clean all

ENV WDIR=/data
WORKDIR $WDIR

# TAG to be passed at build time through `--build-arg TAG=<PYPI_TAG>`. Default: None
ARG TAG=None
# gfal2 is built and copied from gfal2 stage, so we only install non-gfal2 service dependencies
# FIXME: it is probably best to remove it from the requirements.txt file
RUN curl -ksLO https://raw.githubusercontent.com/dmwm/WMCore/$TAG/requirements.txt
RUN cat requirements.txt | grep dbs3-client > req.txt
RUN cat requirements.txt | grep msunmerged | grep -v gfal2 >> req.txt

# Create venv based on environment python to use proper python version,
# install modified requirements,
# and install MSUnmerged itself, without any dependencies
RUN python -m venv .venv && \ 
    .venv/bin/pip install -r req.txt && \
    .venv/bin/pip install --no-deps msunmerged==$TAG

# copy gfal2.so and boost libs from gfal2 stage
COPY --from=gfal2 /tmp/.venv/lib/python3.12/site-packages/gfal2.so $WDIR/.venv/lib/python3.12/site-packages/gfal2.so
COPY --from=gfal2 /usr/local/lib/* /usr/local/lib/.

# add venv to the path to use the proper python3
ENV PATH="$WDIR/.venv/bin:$PATH"

# patch dmwm/WMCore https://github.com/dmwm/WMCore/pull/11955
ADD 11955.patch $WDIR/11955.patch
RUN cd $WDIR/.venv/lib/python3.12/site-packages/WMCore && \
    patch -p 4 -t -i $WDIR/11955.patch && \
    cd $WDIR

# Specific run.sh for MSUnmerged
ADD run.sh $WDIR/run.sh

# and now setup run.sh and manage scripts accordingly
RUN sed -i -e "s,-config.py,-config-unmerged.py,g" /data/run.sh
RUN sed -i -e "s,config.py,config-unmerged.py,g" /data/manage

ENV USER=_reqmgr2ms
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER ${USER}
RUN sudo chown -R $USER.$USER $WDIR
CMD ["python3"]