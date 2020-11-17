#! /bin/sh

export INSTANCE=prod
export REPO=~/rucio-helm-charts # or rucio as an override
export CMS_REPO=~/CMSKubernetes/helm

./install_rucio.sh

