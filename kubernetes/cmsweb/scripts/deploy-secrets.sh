#!/bin/bash
# helper script to deploy given service with given tag to k8s infrastructure

if [ $# -ne 3 ]; then
    echo "Usage: deploy-secrets.sh <namespace> <service-name> <path_to_configuration>"
    exit 1
fi

ns=$1
srv=$2
conf=$3

    # cmsweb configuration area
    echo "+++ configuration: $conf"
    echo "+++ cms service : $srv"
    echo "+++ namespaces   : $ns"

    if [ ! -d $conf/$srv ]; then
	echo "Unable to locate $conf/$srv, please provide proper directory structure like <configuration>/<service>/<files>"
  	exit 1
    fi

    # check (and copy if necessary) hostkey/hostcert.pem files in configuration area of frontend

    if [ "$srv" == "frontend" ] ; then

	if [ ! -f $conf/frontend/hostkey.pem ]; then
        	cp $cmsweb_key $conf/frontend/hostkey.pem
	fi
	
	if [ ! -f $conf/frontend/hostcert.pem ]; then
        	cp $cmsweb_crt $conf/frontend/hostcert.pem
	fi
    fi

    if [ "$srv" == "frontend-ds" ] ; then

	if [ ! -f $conf/frontend-ds/hostkey.pem ]; then
        	cp $cmsweb_key $conf/frontend-ds/hostkey.pem
	fi
    	if [ ! -f $conf/frontend-ds/hostcert.pem ]; then
        	cp $cmsweb_crt $conf/frontend-ds/hostcert.pem
    	fi
    fi
	secretdir=$conf/$srv
        # the underscrore is not allowed in secret names
        osrv=$srv
        srv=`echo $srv | sed -e "s,_,,g"`
        files=""

    if [ "$srv" == "auth-proxy-server" ] || [ "$srv" == "x509-proxy-server" ] || [ "$srv" == "scitokens-proxy-server" ] ; then
        if [ -d $secretdir ] && [ -n "`ls $secretdir`" ] && [ -f $secretdir/client.secrets ]; then
                export CLIENT_SECRET=`grep CLIENT_SECRET $secretdir/client.secrets | head -n1 | awk '{print $2}'`
                export CLIENT_ID=`grep CLIENT_ID $secretdir/client.secrets | head -n1 | awk '{print $2}'`
                export IAM_CLIENT_ID=`grep IAM_CLIENT_ID $secretdir/client.secrets | head -n1 | awk '{print $2}'`
                export IAM_CLIENT_SECRET=`grep IAM_CLIENT_SECRET $secretdir/client.secrets | head -n1 | awk '{print $2}'`
	        if [ -f $secretdir/config.json ]; then
			echo "$(jq '.client_id=env.CLIENT_ID' $secretdir/config.json)" > $secretdir/config.json
			echo "$(jq '.client_secret=env.CLIENT_SECRET' $secretdir/config.json)" > $secretdir/config.json
			echo "$(jq '.iam_client_id=env.IAM_CLIENT_ID' $secretdir/config.json)" > $secretdir/config.json
			echo "$(jq '.iam_client_secret=env.IAM_CLIENT_SECRET' $secretdir/config.json)" > $secretdir/config.json
		fi
        fi
    fi 

        if [ -d $secretdir ] && [ -n "`ls $secretdir`" ]; then
        	for fname in $secretdir/*; do
                	files="$files --from-file=$fname"
                done
        fi

        if [ "$ns" == "dbs" ]; then
        	if [ -f $conf/dbs/DBSSecrets.py ]; then
                        files="$files --from-file=$conf/dbs/DBSSecrets.py"
                fi
                if [ -f $conf/dbs/NATSSecrets.py ]; then
                        files="$files --from-file=$conf/dbs/NATSSecrets.py"
                fi
        fi


        kubectl create secret generic ${srv}-secrets \
                $files --dry-run=client -o yaml | \
                kubectl apply --namespace=$ns -f -

    echo
    echo "+++ list secrets"
    kubectl get secrets -n $ns


