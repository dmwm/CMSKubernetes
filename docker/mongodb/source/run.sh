#!/bin/bash
### This script relies on provided keytab file which will be
### be mounted to /etc/krb area
if [ -d /etc/krb ]; then
  echo "Starting the kinit operation!"
  export keytab=/etc/krb/cmsweb.keytab
  principal=`klist -k "$keytab" | tail -1 | awk '{print $2}'`
  kinit $principal -k -t "$keytab" >/dev/null 2>&1
  if [ $? == 1 ]; then
    echo "Unable to perform kinit operation for cmsweb keytab."
    exit 1
  fi
fi

