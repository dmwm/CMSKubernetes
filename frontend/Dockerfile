FROM cern/cc7-base
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=sw
ADD install.sh $WDIR/install.sh

# ENV ARCH=slc7_amd64_gcc630
# ENV VER=HG1805a
# ENV REPO="comp"
# ENV AREA=/data/cfg/admin
# ENV PKGS="admin frontend"

RUN yum update -y && yum clean all
RUN yum install -y cern-get-certificate fetch-crl
RUN yum install -y git-core zip unzip which file bzip2 e2fsprogs e2fsprogs-libs compat-libstdc++-33 \
    sudo openssl iopenssl-libs openssh openssh-clients \
    perl-Thread-Queue zsh tk freetype perl-ExtUtils-Embed fontconfig \
    perl-Test-Harness perl-Data-Dumper perl-Digest-MD5 perl-Switch perl-Env \
    libX11-devel libX11 libXmu libSM libICE libXcursor libXext libXrandr libXft \
    mesa-libGLU mesa-libGL libXi libXinerama libXft-devel libXrender libXpm \
    libXpm-devel libXext-devel mesa-libGLU-devel
RUN yum clean all

# create bashs link to bash
RUN ln -s /bin/bash /usr/bin/bashs
# add new user
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
# add user to sudoers file
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# switch to user
USER ${USER}

# add fake host certs since we'll pass them via docker at run time
RUN mkdir -p /data/certs
RUN echo "bla" > /data/certs/hostcert.pem
RUN echo "bla" > /data/certs/hostkey.pem
RUN chmod 0600 /data/certs/hostkey.pem

# start the setup
RUN mkdir -p $WDIR
WORKDIR ${WDIR}

# install
RUN $WDIR/install.sh

# run the service
USER $USER
WORKDIR $WDIR
CMD ["/data/cfg/admin/InstallDev", "-s", "start"]
