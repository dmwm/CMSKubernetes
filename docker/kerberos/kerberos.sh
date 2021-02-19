#!/bin/sh
export KRB5CCNAME=/tmp/krb5cc
keytab=$1
echo "using keytab=$keytab"
principal=`klist -k "$keytab" | tail -1 | awk '{print $2}'`
echo "principal=$principal"
kinit $principal -k -f -p -r 7d -l 7d -t "$keytab"
if [ $? == 1 ]; then
    echo "Unable to perform kinit"
    exit 1
fi
klist -k "$keytab"
out=$?
if [ $out -eq 0 ]; then
    kubectl create secret generic krb5cc-secrets \
        --from-file=/tmp/krb5cc --dry-run=client -o yaml | \
        kubectl apply --validate=false -f -
else
    echo "Failed to obtain new kerberos ticket error $out"
    echo "Will not update kerberos-secrets"
fi
