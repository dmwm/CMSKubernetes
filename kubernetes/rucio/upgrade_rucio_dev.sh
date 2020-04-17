#! /bin/bash

export REPO=rucio # or ~/rucio-helm-charts # or rucio
export CMS_REPO=~/CMSKubernetes/helm

export INSTANCE=dev

./upgrade_rucio.sh
