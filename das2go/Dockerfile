FROM cern/cc7-base
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=das
EXPOSE 8212
ADD mongodb.conf $WDIR/mongodb.conf
ADD das_start.sh $WDIR/das_start.sh

RUN yum update -y && yum clean all
RUN yum install -y HEP_OSlibs_CC7 git-core krb5-devel readline-devel\
            bzip2 git-core krb5-devel readline-devel openssl \
            glibc-devel.x86_64 e2fsprogs e2fsprogs-libs compat-libstdc++-33 make vim-enhanced
RUN yum clean all

# We need to run under a user different from root, since our software will not install using the root account
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
USER ${USER}

# start the setup
RUN mkdir -p $WDIR
WORKDIR ${WDIR}

# download mongodb
RUN curl -k -L -O https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel70-3.6.2.tgz
RUN tar xfz mongodb-linux-x86_64-rhel70-3.6.2.tgz
ENV MROOT=$WDIR/mongodb-linux-x86_64-rhel70-3.6.2
# ENV PATH=$PATH:$PWD/mongodb-linux-x86_64-rhel70-3.6.2/bin
RUN mkdir -p $WDIR/mongodb/{logs,db}

# get latest DASMaps
RUN git clone https://github.com/dmwm/DASMaps.git

# download golang and install it
RUN curl -k -L -O https://dl.google.com/go/go1.9.4.linux-amd64.tar.gz
RUN tar xfz go1.9.4.linux-amd64.tar.gz
RUN mkdir $WDIR/gopath
ENV GOROOT=$WDIR/go
ENV GOPATH=$WDIR/gopath
ENV PATH="${GOROOT}/bin:${MROOT}/bin:${WDIR}:${PATH}"
RUN go get github.com/dmwm/cmsauth
RUN go get github.com/vkuznet/x509proxy
RUN go get gopkg.in/mgo.v2
RUN go get github.com/sirupsen/logrus
RUN go get github.com/dmwm/das2go

# build das2go
WORKDIR $GOPATH/src/github.com/dmwm/das2go
RUN make
RUN cat dasconfig.json | sed -e "s,/Users/vk/Work/Languages/Go/gopath,$GOPATH,g" -e "s,/Users/vk/.globus/userkey.pem,/tmp/das/key.pem,g" -e "s,/Users/vk/.globus/usercert.pem,/tmp/das/cert.pem,g" -e "s,/opt/certs,/tmp/das,g" > das.json
ENV PATH="${GOPATH}/src/github.com/dmwm/das2go:${GOPATH}/src/github.com/dmwm/das2go/bin:${PATH}"

# run the service
WORKDIR ${WDIR}
# start mongodb
# ENTRYPOINT mongod --config $WDIR/mongodb.conf
# upload DASMaps into MongoDB
# ENTRYPOINT das_js_import /data/DASMaps/js localhost 8230
# start das2go server
# ENTRYPOINT das_server $GOPATH/src/github.com/dmwm/das2go/das.json 2>&1 1>& das.log < /dev/null &

CMD ["das_start.sh"]
