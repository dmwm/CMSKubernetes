#!/bin/bash

# TMP solution until k8s fix file permission for secret volume
# https://github.com/kubernetes/kubernetes/issues/34982

# Kerberos setup
# This relies on provided keytab file which will be
# be mounted to /etc/krb area
if [ -d /etc/krb ]; then
  echo "Starting the kinit operation!"
  ls /etc/krb
  export keytab=/etc/krb/cmsmonit.keytab
  principal=`klist -k "$keytab" | tail -1 | awk '{print $2}'`
  kinit $principal -k -t "$keytab" >/dev/null 2>&1
  if [ $? == 1 ]; then
    echo "Unable to perform kinit operation for cmsmonit keytab."
    exit 1
  fi
fi

# Define function to copy certificates and fix permissions
copy_and_fix() {
  src=$1
  dest=$2
  if [ -f "$src" ]; then
    cp "$src" "$dest"
    chmod 0400 "$dest"
    # Only chown if needed, and avoid using $USER
    if [ "$(id -u)" -eq 0 ]; then
      # Already root, no chown needed
      :
    else
      chown "$(id -u):$(id -g)" "$dest"
    fi
  fi
}

# Copy certs from /etc/secrets or /etc/robots
[ ! -f /tmp/robotkey.pem ] && copy_and_fix /etc/secrets/robotkey.pem /tmp/robotkey.pem
[ ! -f /tmp/robotcert.pem ] && copy_and_fix /etc/secrets/robotcert.pem /tmp/robotcert.pem
[ ! -f /tmp/robotkey.pem ] && copy_and_fix /etc/robots/robotkey.pem /tmp/robotkey.pem
[ ! -f /tmp/robotcert.pem ] && copy_and_fix /etc/robots/robotcert.pem /tmp/robotcert.pem

# If both cert and key exist, create the proxy
if [ -f /tmp/robotkey.pem ] && [ -f /tmp/robotcert.pem ]; then
  voms-proxy-init -voms cms -rfc -valid 95:50 \
    -key /tmp/robotkey.pem \
    -cert /tmp/robotcert.pem \
    -out /tmp/proxy
fi

#### Use below section for proxy in ms-unmerged service
#    voms-proxy-init -voms cms -rfc -valid 95:50 \
#        -key /tmp/robotkey.pem \
#        -cert /tmp/robotcert.pem \
#        --voms cms:/cms/Role=production --valid 192:00 \
#        -out /tmp/proxy

        
    out=$?
    if [ $out -eq 0 ]; then
        kubectl create secret generic proxy-secrets \
            --from-file=/tmp/proxy --dry-run=client -o yaml | \
            kubectl apply --validate=false -f -

#### Use below section for proxy in ms-unmerged service
#        kubectl create secret generic proxy-secrets-ms-unmerged \
#            --from-file=/tmp/proxy --dry-run=client -o yaml | \
#            kubectl apply --validate=false -f -
            
            
            
    else
        echo "Failed to obtain new proxy, voms-proxy-init error $out"
        echo "Will not update proxy-secrets"
    fi

