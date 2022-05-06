#!/bin/bash
# helper script to encrypt services secrets file using sops-age keys mounted as secrets in Kubernetes clusters
if [ $# -ne 2 ]; then
  echo "The required parameters are missing. Please use encrypt-secrets.sh <namespace> <full-path-to-services-secret-file>"
  exit 1;
fi

namespace=$1
secret_file=$2
echo "Namespace: $namespace"
echo "File to be encrypted: $secret_file"

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
  cp ./sops $HOME/bin
fi

### Get keys from secrets mounted in the desired namespace
kubectl get secrets $namespace-keys-secret -n $namespace --template="{{index .data \"$namespace-keys.txt\" | base64decode}}" > "$namespace-keys.txt"

### Get public key from the secret keys file
cat "$namespace-keys.txt" | awk '{print $4}' | grep "\S" > "$namespace-publickey.txt"
export SOPS_AGE_KEY_FILE="$tmpDir/$namespace-keys.txt"
echo "Key file: $SOPS_AGE_KEY_FILE"
export publickey=`cat "$tmpDir/$namespace-publickey.txt"`

DIR="$(dirname "$secret_file")"
sops -e -age "$publickey" "$secret_file" > "$secret_file.encrypted"
ls -lrt $DIR
rm -rf $tmpDir
