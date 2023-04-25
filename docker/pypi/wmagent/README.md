### WMAgent in Docker using pypi deployment method.

## Requires:
 * Docker to be installed on the host VM (vocmsXXXX)
 * HTcondor schedd to be installed and configured at the host VM
 * CouchDB to be installed on the host VM
 * MariaDB to be installed on the host VM (Depends on the type of relational database to be used MariaDB/Oracle)
 * Service certificates to be present at the host VM
 * `WMAgent.secrets` file to be present at the host VM

## The imlementation is realized through the following files:
 * `Dockerfile` - creates provides all basic requirements for the image and sets all common env variables to both `install.sh` and `run.sh`.
 * `install.sh` - called through `Dockerfile` `RUN` command and provided with a single parameter at build time `WMA_TAG`
 * `run.sh` - set as default `ENTRYPOINT` at container runtime. All agent related configuration parameters are passed as named arguments and used to (re)generate the agent configuration files. All service credentials and schedd caches are accessed via host mount points

**Build options (accepted by `install.sh`):**
* `WMA_TAG=2.2.0.2`

**RUN options (accepted by `run.sh`):**
* `TEAMNAME=testbed-vocms0192`
* `CENTRAL_SERVICES=cmsweb-testbed.cern.ch`
* `AGENT_NUMBER=0`
* `FLAVOR=mysql`


## Building a WMAgent image

The build process may happen at any machine running a Docker Engine.
**Build command:**
```
cd /data
git clone https://github.com/dmwm/CMSKubernetes.git

WMA_TAG=2.2.0.2
docker build --network=host --progress=plain --build-arg WMA_TAG=$WMA_TAG -t wmagent:$WMA_TAG /data/CMSKubernetes/docker/pypi/wmagent/ 2>&1 |tee /data/build-wma.log
```

## Running a WMAgent container
It is a must that only one WMAgent container should be running on a singe agent VM. It is partially guarantied by setting all the host mounts as `private` (see the `:Z` mount options bellow).

One needs to bind mount several directories from the host VM (vocmsXXXX) and also to update the selinux lables with the Z option again at the host.
* /data/certs
* /etc/condor (schedd runs on the host, not the container)
* /tmp
* /data/srv/wmagent/current/install (stateful service and component dirs)
* /data/srv/wmagent/current/config

One also needs to bind mount the secrets file.
* /data/admin/wmagent/WMAgent.secrets

The install and config dirs will be initialized the first time you execute run.sh and a .dockerinit file will be placed to keep track of the initialization. Subsequent container restarts won't touch these directories.

**Run command:**
```
WMA_TAG=2.2.0.2
hostname=`hostname -f`
docker run --network=host --rm --hostname=$hostname --name="WMAgent_$hostname" \
-v /data/certs:/data/certs:Z \
-v /etc/condor:/etc/condor:Z \
-v /tmp:/tmp:Z \
-v /data/srv/wmagent/current/install:/data/srv/wmagent/current/install:Z \
-v /data/srv/wmagent/current/config:/data/srv/wmagent/current/config:Z \
-v /data/admin/wmagent/WMAgent.secrets:/data/admin/wmagent/WMAgent.secrets:Z \
wmagent:$WMA_TAG \
-f oracle \
-t testbed-vocms0192` \
-n 0 \
-c cmsweb-testbed.cern.ch`
```

## Stopping the WMAgent container
In order to stop the WMAgent container one just needs to kill it, the `--rm` option at `docker run` commands assures we leave no leftover containers.

**Shutdown command:**
```
for cont in `docker container list -q`; do docker kill $cont; done
```
