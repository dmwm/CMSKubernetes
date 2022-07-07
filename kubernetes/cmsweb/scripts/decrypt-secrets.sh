#!/bin/bash
# helper script to decrypt file using sops-age keys mounted as secrets in Kubernetes clusters

if [ $# -ne 2 ]; then
  echo "This is helper script to decrypt file using sops-age keys mounted as secrets in Kubernetes clusters. The required parameters are missing. Please use decrypt-secrets.sh <namespace> <full-path-to-enrypted-file>"
  exit 1;
fi

namespace=$1
encrypted_file=$2

echo "Namespace: $namespace"
echo "File to be decrypted: $encrypted_file"

tmpDir=/tmp/$USER/sops

if [ -d $tmpDir ]; then
  rm -rf $tmpDir
fi
mkdir -p $tmpDir
cd $tmpDir

### Download sops binary if it does not exist in the system
if [ -z "`command -v sops`" ]; then
  # download soap in tmp area
  wget -O sops https://github.com/mozilla/sops/releases/download/v3.7.2/sops-v3.7.2.linux.amd64
  chmod u+x sops
  mkdir -p $HOME/bin
  echo "Download and install sops under $HOME/bin"  
  cp ./sops $HOME/bin
fi

pwd
### Get keys from secrets mounted in the desired namespace

kubectl get secrets $namespace-keys-secrets -n $namespace --template="{{index .data \"$namespace-keys.txt\" | base64decode}}" > "$tmpDir/$namespace-keys.txt"

export SOPS_AGE_KEY_FILE="$tmpDir/$namespace-keys.txt"
echo "Key file: $SOPS_AGE_KEY_FILE"

if [[ $encrypted_file == *.encrypted ]]; then
  DIR="$(dirname "$encrypted_file")"
  if [[ $encrypted_file == *.json* ]]; then
    sops --output-type json -d $encrypted_file > $DIR/$(basename $encrypted_file .encrypted)
  else
    sops -d $encrypted_file > $DIR/$(basename $encrypted_file .encrypted)
  fi
  ls -lrt $DIR
fi
rm -rf $tmpDir
