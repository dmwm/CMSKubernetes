# This Dockerfile uses "spider" branch of "cms-htcondor-es" repository
FROM cern/cc7-base:20190724 as builder
RUN yum install -y git python36 python36-virtualenv python36-pip && \
ln -fs /usr/bin/python3 /usr/bin/python && \
ln -fs /usr/bin/pip3.6 /usr/bin/pip

RUN git clone https://github.com/mrceyhun/cms-htcondor-es.git
RUN cd cms-htcondor-es && git checkout spider
RUN pip install -r /cms-htcondor-es/requirements.txt
ENV PYTHONPATH "${PYTHONPATH}:/cms-htcondor-es/src"
ENV REQUESTS_CA_BUNDLE "/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt"

# Install latest kubectl for using with crons
RUN curl -k -O -L https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
mv kubectl /usr/bin && \
chmod +x /usr/bin/kubectl

# copy spider codebase
RUN useradd --uid 1414 -ms /bin/bash spider &&\
chown -R spider /cms-htcondor-es
USER spider
WORKDIR /cms-htcondor-es
