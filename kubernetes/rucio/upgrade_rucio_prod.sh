#! /bin/bash

export REPO=~/rucio-helm-charts/charts # or rucio
export CMS_REPO=~/CMSKubernetes/helm

export INSTANCE=prod

./upgrade_rucio.sh
