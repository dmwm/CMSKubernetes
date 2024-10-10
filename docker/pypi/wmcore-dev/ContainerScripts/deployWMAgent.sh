#! /bin/bash

. ./cms-bot/DMWM/setup-secrets.sh
. ./cms-bot/DMWM/update-deployment.sh
. ./cms-bot/DMWM/latest-dmwm-versions.sh

if [ -z "$WMAGENT_VERSION" ]; then
  export WMAGENT_VERSION=$WMAGENT_LATEST
fi

. ./cms-bot/DMWM/deploy-wmagent.sh

