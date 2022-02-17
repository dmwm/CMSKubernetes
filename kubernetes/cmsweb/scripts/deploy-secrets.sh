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

    if [ "$srv" == "auth-proxy-server" ] ; then
        if [ ! -f $conf/auth-proxy-server/tls.key ]; then
           cp $cmsweb_key $conf/auth-proxy-server/tls.key
        fi
        if [ ! -f $conf/auth-proxy-server/tls.crt ]; then
           cp $cmsweb_crt $conf/auth-proxy-server/tls.crt
        fi
    fi
    
    if [ "$srv" == "x509-proxy-server" ] ; then
        if [ ! -f $conf/x509-proxy-server/tls.key ]; then
           cp $cmsweb_key $conf/x509-proxy-server/tls.key
        fi
        if [ ! -f $conf/x509-proxy-server/tls.crt ]; then
           cp $cmsweb_crt $conf/x509-proxy-server/tls.crt
        fi
    fi
    if [ "$srv" == "scitokens-proxy-server" ] ; then

        if [ ! -f $conf/scitokens-proxy-server/tls.key ]; then
           cp $cmsweb_key $conf/scitokens-proxy-server/tls.key
        fi
        if [ ! -f $conf/scitokens-proxy-server/tls.crt ]; then
           cp $cmsweb_crt $conf/scitokens-proxy-server/tls.crt
        fi
    fi
	secretdir=$conf/$srv
        # the underscrore is not allowed in secret names
        osrv=$srv
        srv=`echo $srv | sed -e "s,_,,g"`
        files=""

### Substitution for APS/XPS/SPS client secrets in config.json      

    if [ "$srv" == "auth-proxy-server" ] || [ "$srv" == "x509-proxy-server" ] || [ "$srv" == "scitokens-proxy-server" ] ; then
       if [ -d $secretdir ] && [ -n "`ls $secretdir`" ] && [ -f $secretdir/client.secrets ]; then
           export CLIENT_SECRET=`grep CLIENT_SECRET $secretdir/client.secrets | head -n1 | awk '{print $2}'`
           export CLIENT_ID=`grep CLIENT_ID $secretdir/client.secrets | head -n1 | awk '{print $2}'`
           export IAM_CLIENT_ID=`grep IAM_CLIENT_ID $secretdir/client.secrets | head -n1 | awk '{print $2}'`
           export IAM_CLIENT_SECRET=`grep IAM_CLIENT_SECRET $secretdir/client.secrets | head -n1 | awk '{print $2}'`
           export COUCHDB_USER=`grep COUCHDB_USER $secretdir/client.secrets | head -n1 | awk '{print $2}'`
           export COUCHDB_PASSWORD=`grep COUCHDB_PASSWORD $secretdir/client.secrets | head -n1 | awk '{print $2}'`
           if [ -f $secretdir/config.json ]; then
              if [ -n "${IAM_CLIENT_ID}" ]; then
                 sed -i -e "s,IAM_CLIENT_ID,$IAM_CLIENT_ID,g" $secretdir/config.json
              fi
              if [ -n "${IAM_CLIENT_SECRET}" ]; then
                 sed -i -e "s,IAM_CLIENT_SECRET,$IAM_CLIENT_SECRET,g" $secretdir/config.json
              fi
              if [ -n "${CLIENT_ID}" ]; then
                 sed -i -e "s,CLIENT_ID,$CLIENT_ID,g" $secretdir/config.json
              fi
              if [ -n "${CLIENT_SECRET}" ]; then
                 sed -i -e "s,CLIENT_SECRET,$CLIENT_SECRET,g" $secretdir/config.json
              fi
              if [ -n "${COUCHDB_USER}" ]; then
                 sed -i -e "s,COUCHDB_USER,$COUCHDB_USER,g" $secretdir/config.json
              fi
              if [ -n "${COUCHDB_PASSWORD}" ]; then
                 sed -i -e "s,COUCHDB_PASSWORD,$COUCHDB_PASSWORD,g" $secretdir/config.json
              fi
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


