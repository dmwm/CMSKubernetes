FROM debian:stable-slim
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=_token

# add new user
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
# add user to sudoers file
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN apt-get update && apt-get -y install curl jq

# Install latest kubectl for using with crons

RUN curl -k -O -L https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN mv kubectl /usr/bin
RUN chmod +x /usr/bin/kubectl


# pass env variable to the build
ARG CMSK8S
ENV CMSK8S=$CMSK8S

# start the setup
RUN mkdir -p $WDIR
WORKDIR ${WDIR}

# run the service
ADD token.sh $WDIR/token.sh

USER $USER
WORKDIR $WDIR
CMD ["./token.sh"]
