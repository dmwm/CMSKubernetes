FROM cern/cc7-base
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=dbs

# ENV ARCH=slc7_amd64_gcc630
# ENV VER=HG1805a
# ENV REPO="comp"
# ENV AREA=/data/cfg/admin
# ENV PKGS="admin backend dbs"

ADD install.sh $WDIR/install.sh
ADD dbs3_start.sh $WDIR/dbs3_start.sh
ADD cernonly2.repo /etc/yum.repos.d/cernonly2.repo

RUN yum update -y && yum clean all
RUN yum install -y git-core zip unzip which file bzip2 e2fsprogs e2fsprogs-libs compat-libstdc++-33 \
    openssl iopenssl-libs openssh openssh-clients \
    perl-Thread-Queue zsh tk freetype perl-ExtUtils-Embed fontconfig \
    perl-Test-Harness perl-Data-Dumper perl-Digest-MD5 perl-Switch perl-Env \
    libX11-devel libX11 libXmu libSM libICE libXcursor libXext libXrandr libXft \
    mesa-libGLU mesa-libGL libXi libXinerama libXft-devel libXrender libXpm \
    libXpm-devel libXext-devel mesa-libGLU-devel
RUN yum clean all

# add fake host certs since we'll pass them via docker at run time
# RUN mkdir -p /data/certs
# RUN touch /data/certs/hostcert.pem
# RUN touch /data/certs/hostkey.pem
# RUN chmod 0600 /data/certs/hostkey.pem

# add new user
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
USER ${USER}

# start the setup
RUN mkdir -p $WDIR
WORKDIR ${WDIR}

# install
RUN $WDIR/install.sh

# Get the configuration
# RUN git clone git://github.com/dmwm/deployment.git cfg
# WORKDIR $WDIR/cfg
# RUN git reset --hard $VER

# Deploy services
# WORKDIR $WDIR
# RUN sed -i -e "s,ssh,#ssh,g" $AREA/InstallDev
# RUN $AREA/InstallDev -A $ARCH -R comp@$VER -S -s image -v $VER -r comp=$REPO -u $USER -p "$PKGS"

# remove fake certs
# USER root
# RUN rm /data/certs/hostcert.pem
# RUN rm /data/certs/hostkey.pem

# start / status / stop
#A=/data/cfg/admin; cd /data; $A/InstallDev -s start)

# run the service
USER $USER
WORKDIR $WDIR
# CMD ["dbs3_start.sh"]
CMD ["$AREA/InstallDev", "-s", "start"]
