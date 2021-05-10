# This Dockerfile uses "spider" branch of "cms-htcondor-es" repository
FROM cern/cc7-base:20210501-2.x86_64

# Build python3.8
RUN yum install -y git gcc openssl-devel bzip2-devel libffi-devel make wget
RUN cd /opt && \
wget https://www.python.org/ftp/python/3.8.7/Python-3.8.7.tgz && \
tar xzf Python-3.8.7.tgz
RUN cd /opt/Python-3.8.7 && ./configure --enable-optimizations && make altinstall
RUN ln -fs /usr/local/bin/python3.8 /usr/bin/python
RUN ln -fs /usr/local/bin/pip3.8 /usr/bin/pip
RUN rm -rf /opt/Python-3.8.7

ENV PATH "${PATH}:/usr/bin/"
RUN git clone https://github.com/mrceyhun/cms-htcondor-es.git && cd cms-htcondor-es && git checkout spider && pip install -r /cms-htcondor-es/requirements.txt
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
