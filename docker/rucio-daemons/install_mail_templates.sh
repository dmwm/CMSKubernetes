#! /bin/bash

yum install -y git && yum clean all && rm -rf /var/cache/yum
cd /tmp
git clone https://github.com/dmwm/rucio.git
cd /tmp/rucio
git checkout CMS
mkdir -p /opt/rucio/etc/mail_templates/
cp etc/mail_templates/* /opt/rucio/etc/mail_templates/
cd /tmp
rm -rf rucio
