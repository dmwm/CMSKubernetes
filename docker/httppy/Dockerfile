FROM debian:latest
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
RUN apt-get update && apt-get install -y python3-cherrypy3
ENV WDIR=/data
WORKDIR $WDIR
ADD server.py $WDIR
CMD ["python3", "server.py"]
