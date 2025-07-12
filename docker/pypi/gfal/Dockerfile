FROM continuumio/miniconda3 AS gfal2-base

# Install gfal2 via conda-forge
RUN conda install -y -c conda-forge \
      python=3.12 \
      gfal2 \
      python-gfal2 \
      openssl \
      libcurl && \
    conda clean -afy

ENV PATH=/opt/conda/bin:$PATH \
    LD_LIBRARY_PATH=/opt/conda/lib:$LD_LIBRARY_PATH

# Optionally test plugin loading
RUN python -c 'import gfal2; ctx = gfal2.creat_context(); print("gfal2 load OK")'
