Includes some useful scripts that are created for CMS Monitoring operation needs

Don't forget to add scripts directory in your PATH environment variable
like `PATH=$PATH:/afs/cern.ch/user/U/USER/private/tools`

## kenv

Script switch between CMSWEB clusters easily.
How to use:

```
. kenv mon # main monitoring cluster
. kenv ha1 # HA1 cluster
. kenv dmmon # Data management monitoring, rucio dataset monitoring services cluster
. kenv vmagg
. kenv mtest # monitoring test cluster
. kenv mine # Your personal cluster if you have
```

## rucioconn

Script to set up rucio connection easily. See https://twiki.cern.ch/twiki/bin/viewauth/CMS/Rucio
How to use: `rucioconn`

## pyspark_run

PySpark run in LxPlus7

## bashrc_suggestions

Suggestions for your LxPlus `.bashrc`

## Other tools you need in:

- `/cvmfs/cms.cern.ch/cmsmon/`

Solution for scram and cmsos :

```
$ cat promtool

#!/bin/bash -e
#CMSDIST_FILE_REVISION=1
eval $(scram unsetenv -sh)
THISDIR=$(dirname $0)
SHARED_ARCH=$(cmsos)
CMD=$(basename $0)
LATEST_VERSION=$(ls -d ${THISDIR}/../${SHARED_ARCH}_*/cms/cmsmon-tools/*/$CMD 2>/dev/null | sed -e 's|.*/cms/cmsmon-tools/||;s|/.*||' | sort | tail -1)
[ -z $LATEST_VERSION ] && >&2 echo "ERROR: Unable to find command '$CMD' for '$SHARED_ARCH' architecture." && exit 1
TOOL=$(ls -d ${THISDIR}/../${SHARED_ARCH}_*/cms/cmsmon-tools/${LATEST_VERSION}/$CMD 2>/dev/null | sort | tail -1)
$TOOL "$@"
```
