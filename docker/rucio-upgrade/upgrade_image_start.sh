#! /bin/bash

if [ -f /opt/rucio/etc/rucio.cfg ]; then
    echo "rucio.cfg already mounted."
else
    echo "rucio.cfg not found. will generate one."
    j2 /tmp/rucio.cfg.j2 | sed '/^\s*$/d' > /opt/rucio/etc/rucio.cfg
fi

j2 /tmp/alembic.ini.j2 | sed '/^\s*$/d' > /tmp/alembic.ini

sleep infinity