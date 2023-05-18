## WMAgent in Docker using pypi deployment method.

### Requires:
 * Docker to be installed on the host VM (vocmsXXXX)
 * HTcondor schedd to be installed and configured at the host VM
 * CouchDB to be installed on the host VM
 * MariaDB to be installed on the host VM (Depends on the type of relational database to be used MariaDB/Oracle)
 * Service certificates to be present at the host VM
 * `WMAgent.secrets` file to be present at the host VM

### The imlementation is realized through the following files:
 * `Dockerfile` - creates provides all basic requirements for the image and sets all common env variables to both `install.sh` and `run.sh`.
 * `install.sh` - called through `Dockerfile` `RUN` command and provided with a single parameter at build time `WMA_TAG`
 * `run.sh` - set as default `ENTRYPOINT` at container runtime. All agent related configuration parameters are passed as named arguments and used to (re)generate the agent configuration files. All service credentials and schedd caches are accessed via host mount points
 * `wmagent-docker-build.sh` - simple script to be used for building a WMAgent docker image
 * `wmagent-docker-run.sh` - simple script to be used for running a WMAgent docker container

**Build options (accepted by `install.sh`):**
* `WMA_TAG=2.2.1rc3`

**RUN options (accepted by `run.sh`):**
* `TEAMNAME=testbed-$HOSTNAME`
* `CENTRAL_SERVICES=cmsweb-testbed.cern.ch`
* `AGENT_NUMBER=0`
* `FLAVOR=mysql`


### Building a WMAgent image

The build process may happen at any machine running a Docker Engine.

**Build command:**
* Using the wrapper script:
```
ssh vocms****
cmst1
cd /data
git clone https://github.com/dmwm/CMSKubernetes.git
cd /data/CMSKubernetes/docker/pypi/wmagent/
./wmagent-docker-build.sh -v 2.2.1rc3
```
* Here is what is happening under the hood:
```
WMA_TAG=2.2.1rc3
docker build --network=host --progress=plain --build-arg WMA_TAG=$WMA_TAG -t wmagent:$WMA_TAG -t wmagent:latest  /data/CMSKubernetes/docker/pypi/wmagent/ 2>&1 |tee /data/build-wma.log
```
**Partial output:**
```
...
#4 [ 1/13] FROM registry.cern.ch/cmsweb/dmwm-base:pypi-20230314@sha256:71cf3825ed9acf4e84f36753365f363cfd53d933b4abf3c31ef828828e7bdf83
#4 DONE 0.0s
...
#14 0.110 =======================================================
#14 0.110 Starting new agent deployment with the following data:
#14 0.110 -------------------------------------------------------
#14 0.111  - WMAgent version         : 2.2.1rc3
#14 0.113  - Python verson           : Python 3.8.16
#14 0.114  - Python Module Path      : /usr/local/lib/python3.8/site-packages
#14 0.114 =======================================================
...
#18 naming to docker.io/library/wmagent:2.2.1rc3 done
#18 DONE 3.3s
```

### Running a WMAgent container

One needs to bind mount several directories from the host VM (vocmsXXXX) and also to update the selinux lables with the Z option again at the host.
* /data/dockerMount/certs
* /etc/condor (schedd runs on the host, not the container)
* /tmp
* /data/dockerMount/srv/wmagent/current/install (stateful service and component dirs)
* /data/dockerMount/srv/wmagent/current/config  (for persisting agent configuration data)
* /data/dockerMount/admin/wmagent               (in order to access the WMAgent.secrets)


The install and config dirs will be initialized the first time you execute run.sh and a .dockerinit file will be placed to keep track of the initialization. Subsequent container restarts won't touch these directories.

**Run command:**

* Initialising the agent for the first time:
```
ssh vocms****
cmst1
cd /data/CMSKubernetes/docker/pypi/wmagent/
# cleaning old agent data:
rm -rf /data/dockerMount/srv/
./wmagent-docker-run.sh -t <team_name> -n <agent_number> -f <db_flavour> -c <central_services> &
```
* Running the agent:
```
./wmagent-docker-run.sh &
```

* Here is what is happening under the hood:
```
WMA_ROOT_DIR=/data/dockerMount

dockerOpts=" \
--network=host \
--rm \
--hostname=`hostname -f` \
--name=wmagent \
--mount type=bind,source=/etc/tnsnames.ora,target=/etc/tnsnames.ora,readonly \
--mount type=bind,source=/etc/condor,target=/etc/condor,readonly \
--mount type=bind,source=/tmp,target=/tmp \
--mount type=bind,source=$WMA_ROOT_DIR/certs,target=/data/certs \
--mount type=bind,source=$WMA_ROOT_DIR/srv/wmagent/current/install,target=/data/srv/wmagent/current/install \
--mount type=bind,source=$WMA_ROOT_DIR/srv/wmagent/current/config,target=/data/srv/wmagent/current/config \
--mount type=bind,source=$WMA_ROOT_DIR/admin/wmagent,target=/data/admin/wmagent/hostadmin \
"

wmaOpts=" \
-f mysql \
-t testbed-vocms0260 \
-n 0 \
-c cmsweb-testbed.cern.ch"

docker run $dockerOpts wmagent $wmaOpts
```

**Partial output:**
```
=======================================================
Starting WMAgent with the following initial data:
-------------------------------------------------------
 - WMAgent Version            : 2.2.1rc3
 - WMAgent TeamName           : testbed-vocms0260
 - WMAgent Number             : 0
 - WMAgent CentralServices    : cmsweb-testbed.cern.ch
 - WMAgent Host               : vocms0260.cern.ch
 - WMAgent Config             : /data/srv/wmagent/current/config
 - WMAgent Relational DB type : oracle
 - Python verson              : Python 3.8.16
 - Python Module Path         : /usr/local/lib/python3.8/site-packages
=======================================================
...
```

**NOTE:**
Currently, it is a must that only one WMAgent container should be running on a singe agent VM. It is partially guarantied by setting setting the `--name=wmagent` parameter at the `docker run` command above. But it is infact possible to over come this by setting a different name of the new container, but bare in mind all unpredicted consiquenses of such action. If one tries tr start two containers with the same name, the expected errr is:
```
docker run $dockerOpts wmagent:$WMA_TAG $wmaOpts

docker: Error response from daemon: Conflict. The container name "/wmagent" is already in use by container "c4c64688a75b6ac8f5cc5e4c951db324b2441ec1434f2e1d604a49d8009ff2a1". You have to remove (or rename) that container to be able to reuse that name.
See 'docker run --help'
```




### Checking container status
```
ssh vocms****

docker container ps
CONTAINER ID   IMAGE             COMMAND                CREATED       STATUS       PORTS     NAMES
78d7e1baa3df   wmagent:2.2.1rc3   "./run.sh -f oracle ..."   2 hours ago   Up 2 hours             wmagent

```

## Stopping the WMAgent container
In order to stop the WMAgent container one just needs to kill it, the `--rm` option at `docker run` commands assures we leave no leftover containers.

**Shutdown command:**
```
docker kill wmagent
```

### Enforce container reinitialisation at the host:
The WMAgent needs to preserve its configuration and initialisation data permanently at the host. For the purpose we use Host to Docker bind mounts.
Once a specific WMAgent image has been run for the first time it leaves a small set of .dockerInit files at all places where permanent data(like config files and job caches) at the host is preserved.
On any further restart of the container, hence the WMAgent itself, we do not go through all the initialisation steps again if we find the
relevnat .dockerInit file and the $WMA_BUILD_ID hash contained there matches the $WMA_BUILD_ID of the currently starting container.
In order for one to enforce reinitialisation steps to be performed one needs to delete all .dockerInit fieles and restart the wmagent container.

**NOTE: This reintialisation may result in losing previous job caches and database records**
**Reintialisation command:**
```
docker kill wmagent

sudo find /data/dockerMount -name .dockerInit -delete

docker run $dockerOpts wmagent:$WMA_TAG $wmaOpts
```

**Partial output:**
```
=======================================================
Starting WMAgent with the following initialisation data:
-------------------------------------------------------
 - WMAgent Version            : 2.2.1rc3
...
=======================================================
-------------------------------------------------------
Start: Performing checks for successful Docker initialisation steps...
WMA_BUILD_ID: 110b443165e3b5a4ba569b8a1ab063a616132602e55ba06b0c3e89a01e643f31
dockerInitId: /data/admin/wmagent/hostadmin/.dockerInit:
...
ERROR
-------------------------------------------------------
Start: Performing Docker image to Host initialisation steps
...
Done: Performing Docker image to Host initialisation steps
-------------------------------------------------------
-------------------------------------------------------
Start: Performing checks for successful Docker initialisation steps...
WMA_BUILD_ID: 110b443165e3b5a4ba569b8a1ab063a616132602e55ba06b0c3e89a01e643f31
dockerInitId: 110b443165e3b5a4ba569b8a1ab063a616132602e55ba06b0c3e89a01e643f31
OK
-------------------------------------------------------
...
```

### Connecting to the container

First login at the VM and from there connect to the container:

**Login sequence:**
```
docker exec -it wmagent /bin/bash
...
(WMAgent-2.2.1rc3) [cmst1@vocms0260:current]$ manage status
```