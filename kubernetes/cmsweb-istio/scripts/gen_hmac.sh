#!/bin/bash
if [ "$#" -ne 1 ]; then
    echo "usage: gen_hmac.sh <hmac_file>"
    exit 1
fi
perl -e 'open(R, "< /dev/urandom") or die; sysread(R, $K, 20) or die; print $K' > $1
