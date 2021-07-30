#! /bin/bash

j2 /tmp/globus-config.yml.j2 | sed '/^\s*$/d' > /opt/rucio/etc/globus-config.yml

/start-daemon.sh
