#!/bin/bash
echo "SETTING KERBEROS CONFIGURATION"
if [ -f /etc/secrets/msuccarm.keytab ]; then
    echo "FOUND KEYTABFILE"
    export keytab=/etc/secrets/msuccarm.keytab
    principal=`klist -k "$keytab" | tail -1 | awk '{print $2}'`
#    kinit $principal -k -t -r "5d" "$keytab"
    echo "ABOUT TO PERFORM K5START"
    k5start $principal -K 30 -b -f "$keytab"
    echo "JUST PERFOMED K5START"
    if [ $? == 1 ]; then
        echo "Unable to perform kinit."
        echo "If you are installing a DQM GUI on lxplus or any other private machine, please comment lines from this block and proceed as usual"
        exit 1
    else
        klist
    fi
else
    echo "DIDN'T FIND KEYTAB FILE"
fi
