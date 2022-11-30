# Install xrootd dependencies
# cmake
yum -y install wget
wget https://cmake.org/files/v3.12/cmake-3.12.3.tar.gz
tar zxvf cmake-3.*
./cmake-3.*/bootstrap --prefix=/usr/local
make -j$(nproc)
make install
# lib development
yum -y install zlib-devel
# openssl development
yum -y install openssl-devel
# python development
yum -y install python3-devel
# uuid development
yum -y install libuuid-devel
# devtoolset-7
yum -y install centos-release-scl
yum-config-manager --enable rhel-server-rhscl-7-rpms
yum -y install devtoolset-7
# wheel
python3 -m pip install wheel
# Install xrootd
python3 -m pip install xrootd --user

# Install K5start
yum -y install kstart

# Clone repository
git clone https://github.com/cms-DQM/dqmgui.git
cd dqmgui
echo $PWD
python3 -m pip install -r /home/cmsusr/dqmgui/python/requirements.txt -t /home/cmsusr/dqmgui/python/.python_packages
