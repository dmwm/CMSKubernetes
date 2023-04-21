### WMAgent in Docker using the deployment scripts.

Requires Docker to be installed an agent VM (vocmsXXXX) running a schedd.

Default build options are defined in `install.sh`. Builds a Docker image via standard deployment scripts. The image only contains things common to all agents. 
```
WMA_TAG=2.2.0.2
DEPLOY_TAG=master
WMA_ARCH=slc7_amd64_gcc630
REPO="comp=comp"
```

Run options are defined in `run.sh`. A JobSubmitter patch from PR 9453 is required if you want to run workflows. Configures things unique to an agent running in a container, initializes the agent config and databases
```
WMA_TAG=2.2.0.2
DEPLOY_TAG=master
TEAMNAME=testbed-erik
CENTRAL_SERVICES=esg-dmwm-dev1.cern.ch
AG_NUM=0
FLAVOR=mysql
PATCHES="9453"
```
`WMA_TAG` and `DEPLOY_TAG` must match what is in install.sh

Building the image

```
WMA_TAG=2.2.0.2
docker build --network=host --build-arg WMA_TAG=$WMA_TAG -t wmagent:$WMA_TAG .
```

Running a WMAgent container

For now when you start a container it simply drops you to a login shell, allowing you to run `run.sh` manually. You must bind mount several directories and update the selinux lables with the Z option (on vocmsXXXX hosts).
* /data/certs
* /etc/condor (schedd runs on the host, not the container)
* /tmp
* /data/srv/wmagent/current/install (stateful service and component dirs)
* /data/srv/wmagent/current/config

You also need to bind mount the secrets file.
* /data/admin/wmagent/WMAgent.secrets

The install and config dirs will be initialized the first time you execute run.sh and a .dockerinit file will be placed to keep track of the initialization. Subsequent container restarts won't touch these directories.

Run command:
```
docker run --network=host --rm -h `hostname -f` -it \
-v /data/certs:/data/certs:Z \
-v /etc/condor:/etc/condor:Z \
-v /tmp:/tmp:Z \
-v /data/srv/wmagent/current/install:/data/srv/wmagent/current/install:Z \
-v /data/srv/wmagent/current/config:/data/srv/wmagent/current/config:Z \
-v /data/admin/wmagent/WMAgent.secrets:/data/admin/wmagent/WMAgent.secrets:Z \
<image>
```
