#!/bin/bash

# Print a message to indicate the script is running
echo "authmap-preprod.sh is running"

sleep $((RANDOM % 601))

/data/srv/current/config/frontend/mkauthmap  -c /data/srv/current/config/frontend/mkauth.conf -o /data/srv/state/frontend/etc/authmap.json --cert /etc/robots/robotcert.pem --key /etc/robots/robotkey.pem --ca-cert /etc/ssl/certs/CERN-bundle.pem' && '[ $? -ne 0 ] && /bin/bash /data/alerts.sh
