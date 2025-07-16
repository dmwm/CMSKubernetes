FROM registry.cern.ch/cmsweb/gfal:deb-py312-113-stable as gfal
FROM registry.cern.ch/cmsweb/dmwm-base:pypi-20250716-stable
ENV WDIR=/data
WORKDIR $WDIR

# Copy Miniconda environment from gfal image
COPY --from=gfal /opt/conda /opt/conda

# Set PATH and LD_LIBRARY_PATH to use gfal2 (Miniconda) environment
ENV PATH=/opt/conda/bin:$PATH \
    LD_LIBRARY_PATH=/opt/conda/lib:$LD_LIBRARY_PATH \
    PYTHONPATH=/opt/conda/lib/python3.12/site-packages:$PYTHONPATH

# TAG to be passed at build time through `--build-arg TAG=<PYPI_TAG>`. Default: None
ARG TAG=None
ADD run.sh $WDIR/run.sh
# since we install gfal via external image we'll skip it for installation
# of msunmerged, but to satisfy dependencies we'll install them first
RUN curl -ksLO https://raw.githubusercontent.com/dmwm/WMCore/$TAG/requirements.txt
RUN cat requirements.txt | grep msunmerged | grep -v gfal2 > req.txt
RUN pip install --no-cache-dir -r req.txt
RUN pip install --no-deps msunmerged==$TAG 
RUN sed -i -e "s,-config.py,-config-unmerged.py,g" /data/run.sh
RUN sed -i -e "s,config.py,config-unmerged.py,g" /data/manage

# Optional: sanity check
RUN echo "Sanity check: Python from $(which python)" && \
    python -c 'import gfal2; ctx = gfal2.creat_context(); print("gfal2 load OK")'
# (Optional) Print out library linking as sanity check
RUN echo "Libssl link check:" && ldd $(python -c "import libssl; print(libssl.__file__)") || true

ENV USER=_reqmgr2ms
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER ${USER}
RUN sudo chown -R $USER.$USER $WDIR
CMD ["python3"]
