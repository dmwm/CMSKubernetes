FROM python:3.12-slim-bookworm
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
RUN apt-get update
RUN apt-get install -y curl libcurl4 libcurl4-openssl-dev
RUN ln -s /usr/bin/python3 /usr/bin/python
ENV WDIR=/data
WORKDIR $WDIR
RUN curl -ksL https://repo.anaconda.com/miniconda/Miniconda3-py312_25.5.1-0-Linux-x86_64.sh -o $WDIR/miniconda.sh \
    && chmod +x $WDIR/miniconda.sh
RUN $WDIR/miniconda.sh -b -p $WDIR/miniconda
ENV PATH $WDIR/miniconda/bin:$PATH
RUN conda install -y -c conda-forge python-gfal2
RUN conda clean --all -f -y
