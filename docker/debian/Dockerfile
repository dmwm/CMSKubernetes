FROM debian:latest
RUN apt-get update && \
    apt-get install -y curl libcurl4 libcurl4-openssl-dev vim python3-pycurl pip sudo less && \
    apt-get clean && \
    rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*