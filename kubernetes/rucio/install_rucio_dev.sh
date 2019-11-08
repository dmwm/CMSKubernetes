#! /bin/sh

export INSTANCE=dev
export REPO=rucio # or ~/rucio-helm-charts as an override
export CMS_REPO=~/CMSKubernetes/helm

./install_rucio.sh

