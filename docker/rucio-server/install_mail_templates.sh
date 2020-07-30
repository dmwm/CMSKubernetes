#! /bin/bash

yum install -y git && yum clean all && rm -rf /var/cache/yum
cd /tmp
git clone https://github.com/dmwm/rucio.git
cd /tmp/rucio
git checkout CMS
mkdir -p /root/mail_templates/
cp etc/mail_templates/* /root/mail_templates/
cd /tmp
rm -rf rucio
yum autoremove -y git

