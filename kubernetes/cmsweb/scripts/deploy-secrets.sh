#!/bin/bash
# helper script to deploy given service with given tag to k8s infrastructure

if [ $# -ne 3 ]; then
    echo "Usage: deploy-secrets.sh <namespace> <service-name> <path_to_configuration>"
    exit 1
fi

cluster_name=$(kubectl config get-clusters | grep -v NAME)

ns=$1
srv=$2
conf=$3
decrypted_files=()
tmpDir=/tmp/$USER/sops
if [ -d $tmpDir ]; then
    rm -rf $tmpDir
fi
mkdir -p $tmpDir
cd $tmpDir
decrypted_dir="$tmpDir/decrypted"
mkdir -p "$decrypted_dir"

installSops() {
    # download soap in tmp area
    wget -O sops https://github.com/mozilla/sops/releases/download/v3.7.2/sops-v3.7.2.linux.amd64
    chmod u+x sops
    mkdir -p $HOME/bin
    echo "Download and install sops under $HOME/bin"
    cp ./sops $HOME/bin
    SOPS="$HOME/bin/sops"
}

# check if sops is set at the current machine's path:
SOPS=$(command -v sops) || installSops ||  { err=$?; echo "`sops` command is not properly setup"; exit $err; }

# check if sops is executable:
[[ -e $SOPS ]] || installSops || { err=$?; echo "$SOPS is not executable"; exit $err; }

# check if sops is the expected version:
[[ $($SOPS --version) =~ sops[[:blank:]]+3\.[7-9]+\.[0-9]+.* ]] || installSops || { err=$?; echo "$SOPS is not the expected version"; exit $err; }

# cmsweb configuration area
echo "+++ cluster name: $cluster_name"
echo "+++ configuration: $conf"
echo "+++ cms service : $srv"
echo "+++ namespaces   : $ns"
echo "+++ secretref   : $secretref"

if [ ! -d $conf/$srv ]; then
    echo "Unable to locate $conf/$srv, please provide proper directory structure like <configuration>/<service>/<files>"
    exit 1
fi

# Get SOPS decryption key (if it's not there) and set it as the default decryption file
sopskey=$SOPS_AGE_KEY_FILE
kubectl get secrets $ns-keys-secrets -n $ns --template="{{index .data \"$ns-keys.txt\" | base64decode}}" > "$tmpDir/$ns-keys.txt"
export SOPS_AGE_KEY_FILE="$tmpDir/$ns-keys.txt"
echo "Key file: $SOPS_AGE_KEY_FILE"

# check (and copy if necessary) hostkey/hostcert.pem files in configuration area of frontend
if [ "$srv" == "frontend" ]; then
    if [ ! -f $conf/frontend/hostkey.pem ]; then
        cp $cmsweb_key $conf/frontend/hostkey.pem
    fi

    if [ ! -f $conf/frontend/hostcert.pem ]; then
        cp $cmsweb_crt $conf/frontend/hostcert.pem
    fi
fi

if [ "$srv" == "frontend-ds" ]; then
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
srv=$(echo $srv | sed -e "s,_,,g")
files=""
secretfiles=""
### Substitution for APS/XPS/SPS client secrets in config.json
if [ "$srv" == "auth-proxy-server" ] || [ "$srv" == "x509-proxy-server" ] || [ "$srv" == "scitokens-proxy-server" ]; then
    for fname in $secretdir/*; do
        if [[ $fname == *.encrypted ]]; then
            decrypted_fname="$decrypted_dir/$(basename "$fname" .encrypted)"
            if [[ $fname == *.json* ]]; then
                $SOPS --output-type json -d $fname > $decrypted_fname
            else
                $SOPS -d $fname > $decrypted_fname
            fi
            decrypted_files+=("$decrypted_fname")
        fi
    done
    if [ -d $secretdir ] && [ -n "$(ls $secretdir)" ] && [ -f $secretdir/client.secrets ]; then
        export CLIENT_SECRET=$(grep CLIENT_SECRET $secretdir/client.secrets | head -n1 | awk '{print $2}')
        export CLIENT_ID=$(grep CLIENT_ID $secretdir/client.secrets | head -n1 | awk '{print $2}')
        export IAM_CLIENT_ID=$(grep IAM_CLIENT_ID $secretdir/client.secrets | head -n1 | awk '{print $2}')
        export IAM_CLIENT_SECRET=$(grep IAM_CLIENT_SECRET $secretdir/client.secrets | head -n1 | awk '{print $2}')
        export COUCHDB_USER=$(grep COUCHDB_USER $secretdir/client.secrets | head -n1 | awk '{print $2}')
        export COUCHDB_PASSWORD=$(grep COUCHDB_PASSWORD $secretdir/client.secrets | head -n1 | awk '{print $2}')
        if [ -f $secretdir/config.json ]; then
            sed -i "s/TEST_CLUSTER_NAME/$cluster_name/" $secretdir/config.json
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

if [ -d $secretdir ] && [ -n "$(ls $secretdir)" ]; then
    for fname in $secretdir/*; do
	# replace CLUSTER_NAME in service config file with current cluster name
	if [[ $fname == */config*.py ]]; then
            if [[ $cluster_name == cmsweb-test[0-9]* ]]; then
		echo "Updating config file $fname for the $cluster_name cluster."
                sed -i "s/TEST_CLUSTER_NAME/$cluster_name/" $fname
            fi
	fi
        if [[ $fname == *.encrypted ]]; then
            if [[ $fname == *.json* ]]; then
                decrypted_fname="$decrypted_dir/$(basename "$fname" .encrypted)"
                $SOPS --output-type json -d $fname > $decrypted_fname
            else
                decrypted_fname="$decrypted_dir/$(basename $fname .encrypted)"
                $SOPS -d $fname > $decrypted_fname
            fi
            decrypted_files+=("$decrypted_fname")
            echo "Decrypted file $decrypted_fname"
        fi
        if [[ ! $files == *$fname* ]]; then
            files="$files --from-file=$fname"
            secretfiles="$secretfiles $fname"
        fi
    done
fi

if [ "$ns" == "dbs" ]; then
    for fname in $conf/dbs/*; do
        if [[ $fname == *.encrypted ]]; then
            $SOPS -d $fname >$conf/dbs/$(basename $fname .encrypted)
        fi
    done
    if [ -f $conf/dbs/DBSSecrets.py ]; then
        files="$files --from-file=$conf/dbs/DBSSecrets.py"
        secretfiles="$secretfiles DBSSecrets.py"
    fi
    if [ -f $conf/dbs/NATSSecrets.py ]; then
        files="$files --from-file=$conf/dbs/NATSSecrets.py"
        secretfiles="$secretfiles NATSSecrets.py"

    fi
fi

kubectl create secret generic ${srv}-secrets \
    $files --dry-run=client -o yaml |
    kubectl apply --namespace=$ns -f -

    echo "Deleting decrypted files..."
    for decrypted_file in "${decrypted_files[@]}"; do
      rm -f "$decrypted_file"
    done

export SOPS_AGE_KEY_FILE=$sopskey
echo
echo "+++ list secrets"
kubectl get secrets -n $ns
rm -rf $tmpDir
