#!/bin/bash

if [ $# -lt 2 ]; then
     echo "The required parameters for service, tag, namespace, and the secrets are missing. Please use deploy-srv.sh <service> <env> <path-to-secrets> <namespace>"
     exit 1;
fi

srv=$1
cmsweb_env=$2
env=$(echo $cmsweb_env | cut -f1 -d-)
secretdir=$3
namespace=$4

echo $srv
echo "$env"

tmpDir=/tmp/$USER/sops
if [ -d $tmpDir ]; then
    rm -rf $tmpDir
fi
mkdir -p $tmpDir

if [ -z "$(command -v sops)" ]; then
    # download soap in tmp area
    wget -O sops https://github.com/mozilla/sops/releases/download/v3.7.2/sops-v3.7.2.linux.amd64
    chmod u+x sops
    mkdir -p $HOME/bin
    echo "Download and install sops under $HOME/bin"
    cp ./sops $HOME/bin
    popd +0
fi

kubectl get secrets $namespace-keys-secrets -n $namespace --template="{{index .data \"$namespace-keys.txt\" | base64decode}}" > "$tmpDir/$namespace-keys.txt"

export SOPS_AGE_KEY_FILE="$tmpDir/$namespace-keys.txt"
echo "Key file: $SOPS_AGE_KEY_FILE"

echo $PWD
mkdir -p $srv/secrets/
secretsFiles=`ls -1  $secretdir/`
echo $secretsFiles
if [ "$srv" == "auth-proxy-server" ] || [ "$srv" == "x509-proxy-server" ] || [ "$srv" == "scitokens-proxy-server" ]; then
    for fname in $secretdir/*; do
        if [[ $fname == *.encrypted ]]; then
            if [[ $fname == *.json* ]]; then
		    $HOME/bin/sops --output-type json -d $fname > $srv/templates/secrets/(basename $fname .encrypted).dec.yaml
            else
                $HOME/bin/sops -d $fname > $srv/templates/secrets/(basename $fname .encrypted).dec.yaml
            fi
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
f [ -d $secretdir ] && [ -n "$(ls $secretdir)" ]; then
    for fname in $secretfiles; do
	# replace CLUSTER_NAME in service config file with current cluster name
	if [[ $fname == */config*.py ]]; then
            if [[ $cluster_name == cmsweb-test[0-9]* ]]; then
		echo "Updating config file $fname for the $cluster_name cluster."
                sed -i "s/TEST_CLUSTER_NAME/$cluster_name/" $repository/$fname
            fi
	fi
        if [[ $fname == *.encrypted ]]; then
            if [[ $fname == *.json* ]]; then
                $HOME/bin/sops --config <(echo '') --output-type json -d $repository/$fname > $srv/templates/secrets/$(basename $fname .encrypted).dec.yaml
            else
                $HOME/bin/sops --config <(echo '') -d $repository/$fname > $srv/templates/secrets/$(basename $fname .encrypted).dec.yaml
            fi
            fname=$secretdir/$(basename $fname .encrypted)
            echo "Decrypted file $fname"
	else
            cp $repository/$fname $srv/templates/secrets/$(basename $fname .encrypted).dec.yaml
        fi
    done
fi

if [ "$ns" == "dbs" ]; then
    for fname in $repository/dbs/*; do
        if [[ $fname == *.encrypted ]]; then
            $HOME/bin/sops --config <(echo '') -d $fname >$srv/templates/secrets/$(basename $fname .encrypted).dec.yaml
        fi
    done
    if [ -f $repository/dbs/DBSSecrets.py ]; then
        cp $repository/DBSSecrets.py $srv/templates/secrets/DBSSecrets.py.dec.yaml
    fi
    if [ -f $repository/dbs/NATSSecrets.py ]; then
        cp $repository/NATSSecrets.py $srv/templates/secrets/NATSSecrets.py.dec.yaml
    fi
fi


#for file in $secretsFiles
#do
#  echo $file
#  touch secrets/${file}.dec.yaml;
#  echo "created the file.."
#  if [[ $file == *.encrypted ]]; then
#    DIR="$(dirname "$file")"
#    if [[ $encrypted_file == *.json* ]]; then
#      sops ---config <(echo '') --output-type json -d $repository/$file > $srv/secrets/${file};
#    else
#      sops --config <(echo '') -d $repository/$file > $srv/secrets/${file};
#    fi
#    ls -lrt $DIR
#    else 
#      touch $srv/secrets/${file};
#      cp $repository/$file $srv/templates/secrets/${file};
#    fi  
#done

















