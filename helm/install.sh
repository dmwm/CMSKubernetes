#!/bin/bash

if [ $# -lt 2 ]; then
     echo "The required parameters for service, tag, namespace, and the secrets are missing. Please use deploy-srv.sh <service> <env> <path-to-secrets> <namespace>"
     exit 1;
fi

srv=$1
cmsweb_env=$2
env=$(echo $cmsweb_env | cut -f1 -d-)
repository=$3
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

#ls -1  $repository/ | while read file; mkdir -p $OLDPWD/$srv/templates/secrets/ && touch $OLDPWD/$srv/templates/secrets/${file}.dec.yaml; do sops -d --pgp $SOPS_AGE_KEY_FILE $repository/$file > $OLDPWD/$srv/templates/secrets/${file}.dec.yaml; done
echo $PWD
mkdir -p $srv/secrets/
secretsFiles=`ls -1  $repository/`
echo $secretsFiles
for file in $secretsFiles
do
  echo $file
  touch secrets/${file}.dec.yaml;
  echo "created the file.."
  if [[ $file == *.encrypted ]]; then
    DIR="$(dirname "$file")"
    if [[ $encrypted_file == *.json* ]]; then
      sops ---config <(echo '') --output-type json -d $repository/$file > $srv/secrets/${file};
    else
      sops --config <(echo '') -d $repository/$file > $srv/secrets/${file};
    fi
    ls -lrt $DIR
    else 
      touch $srv/secrets/${file};
      cp $repository/$file $srv/templates/secrets/${file};
    fi  
done

















