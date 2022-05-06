FROM cmscloud/cc7-cvmfs:latest

# Install xrootd and it's dependencies
RUN sudo yum -y install wget && sudo wget https://cmake.org/files/v3.12/cmake-3.12.3.tar.gz && sudo tar zxvf cmake-3.* && ./cmake-3.*/bootstrap --prefix=/usr/local && sudo make -j$(nproc) && sudo make install && sudo yum -y install zlib-devel  openssl-devel install python3-devel libuuid-devel centos-release-scl && sudo yum-config-manager --enable rhel-server-rhscl-7-rpms && sudo yum -y install devtoolset-7 && sudo python3 -m pip install wheel && sudo python3 -m pip install xrootd --user && sudo yum clean all && sudo rm -rf /var/cache/yum

# Clone repo and install python dependencies
RUN sudo git clone https://github.com/cms-DQM/dqmgui.git && cd dqmgui && pwd && ls -l python && sudo python3 -m pip install -r /home/cmsusr/dqmgui/python/requirements.txt -t /home/cmsusr/dqmgui/python/.python_packages && pwd && ls -l
WORKDIR $PWD/dqmgui/

CMD ["/bin/bash"]
# CMD sudo bash ./run.sh
CMD sudo /usr/sbin/crond -n