# WMAgent in Docker using pypi deployment method

The way how we have designed the WMAgent services to be split and run among different
docker containers (all running at the same host) is as follows:
* One docker container for MariaDB server
* One docker container for CouchDB server
* One docker container for all WMAgent components

Connection between all containers is to be established through the host's network and loopback device (ip: 127.0.0.1)

## Overview
### Requires:
 * Docker to be installed on the host VM (vocmsXXXX)
 * HTcondor schedd to be installed and configured at the host VM
 * CouchDB to be installed on the host VM and accessible through 127.0.0.1
 * MariaDB to be installed on the host VM and accessible through 127.0.0.1 (Depends on the type of relational database to be used MariaDB/Oracle)
 * Service certificates to be present at the host VM
 * `WMAgent.secrets` file to be present at the host VM

### The implementation is realized through the following files:
 * `Dockerfile` - provides all basic requirements for the image and sets all common environment variables to both `install.sh` and `init.sh`.
 * `install.sh` - called through `Dockerfile` `RUN` command and provided with a single parameter at build time `WMA_TAG`
 * `init.sh` - set as default `ENTRYPOINT` at container runtime. All agent related configuration parameters are taken from `WMAgent.secrets` file and used to (re)generate the agent configuration files. All service credentials and schedd caches are accessed via host mount points
 * `wmagent-docker-build.sh` - simple script to be used for building a WMAgent docker image
 * `wmagent-docker-run.sh` - simple script to be used for running a WMAgent docker container

**Build options (accepted by `install.sh`):**
* `WMA_TAG=2.2.3.2`

**RUN options (accepted by `init.sh`):**
* `None` - All agent configuration parameters are now fetched from a single place - `WMAgent.secrets` file


### Building a WMAgent image

The build process may happen at any machine running a Docker Engine.

**Build command:**
* Using the wrapper script to build WMAgent locally:
```
ssh vocms****
cmst1
cd /data
git clone https://github.com/dmwm/CMSKubernetes.git
cd /data/CMSKubernetes/docker/pypi/wmagent/
./wmagent-docker-build.sh -t 2.2.3.2
```
* Using the wrapper script to build and upload WMAgent to registry.cern.ch:
```
./wmagent-docker-build.sh -t 2.2.3.2 -p
```
* Here is what happens under the hood:
```
WMA_TAG=2.2.3.2
docker build --network=host --progress=plain --build-arg WMA_TAG=$WMA_TAG -t local/wmagent:$WMA_TAG -t local/wmagent:latest  /data/CMSKubernetes/docker/pypi/wmagent/ 2>&1 |tee /data/build-wma.log
```
**Partial output:**
```
...
#4 [ 1/13] FROM registry.cern.ch/cmsweb/dmwm-base:pypi-20230314@sha256:71cf3825ed9acf4e84f36753365f363cfd53d933b4abf3c31ef828828e7bdf83
#4 DONE 0.0s
...
#18 0.144 =======================================================================
#18 0.144 Starting new WMAgent deployment with the following initialization data:
#18 0.144 -----------------------------------------------------------------------
#18 0.144  - WMAgent Version            : 2.2.3.2
#18 0.144  - WMAgent User               : cmst1
#18 0.144  - WMAgent Root path          : /data
#18 0.148  - Python  Version            : Python 3.8.16
#18 0.148  - Python  Module path        : /usr/local/lib/python3.8/site-packages
#18 0.148 =======================================================================
#18 0.148
#18 0.148 -----------------------------------------------------------------------
#18 0.148 Start Installing wmagent:2.2.3.2 at /usr/local
...
#21 naming to docker.io/local/wmagent:2.2.3.2 done
#21 naming to docker.io/local/wmagent:latest done
#21 DONE 3.2s
```

### Running a WMAgent container

We needs to bind mount several directories from the host VM (vocmsXXXX).
And we also need to have a single directory to contain all the host mounts.
(It will be created by the `wmagent-docker-run.sh` script if missing)

Single host Mount area:
* /data/dockerMount/

List of host mounts:
* /data/certs
* /etc/condor (schedd runs on the host, not the container)
* /etc/tnsnames.ora  (for agents using Oracle database)
* /tmp
* /data/dockerMount/srv/wmagent/<WMA_TAG>/install \ (stateful service and component directories)
* /data/dockerMount/srv/wmagent/<WMA_TAG>/config \  (for persisting agent configuration data)
* /data/dockerMount/srv/wmagent/<WMA_TAG>/logs \  (for persisting log files - **NOTE:** We need to redirect all components' logs to this directory)
* /data/dockerMount/admin/wmagent               (in order to access the WMAgent.secrets)


The `install`, `config` and `logs` directories will be created at the host the first time you execute `wmagent-docker-run.sh`.

**Run command:**

* Initializing the agent for the first time:
```
ssh vocms****
cmst1
cd /data/CMSKubernetes/docker/pypi/wmagent/
./wmagent-docker-run.sh -t <WMA_TAG> &
```
* Initializing the agent for the first time using a docker image from registry.cern.ch:
```
./wmagent-docker-run.sh -t <WMA_TAG> -p &
```

**Partial output:**
```
Start initialization

=======================================================
Starting WMAgent with the following initialization data:
-------------------------------------------------------
 - WMAgent Version            : 2.2.3.2
 - WMAgent User               : cmst1
 - WMAgent Root path          : /data
 - WMAgent Host               : unit02.cern.ch
 - WMAgent TeamName           : testbed-unit02
 - WMAgent Number             : 0
 - WMAgent Relational DB type : mysql
 - Python  Version            : Python 3.8.16
 - Python  Module path        : /usr/local/lib/python3.8/site-packages
=======================================================

-------------------------------------------------------
Start: Performing basic_checks
...
-------------------------------------------------------
Start: Performing checks for successful Docker initialization steps...
WMA_BUILD_ID: 7b7c7f3cc454ee1552dff4b10ece311f98e6a183c977978833e6ee7faff92974
dockerInitId: 7b7c7f3cc454ee1552dff4b10ece311f98e6a183c977978833e6ee7faff92974
OK

Docker container has been initialized! However you still need to:
  1) Double check agent configuration: less /data/[dockerMount]/srv/wmagent/current/config/config.py
  2) Start the agent with one of the following commands:
     * From inside a running wmagent container:
       docker exec -it wmagent bash
       manage start-agent

     * From the host:
       docker stop wmagent
       ./wmagent-docker-run.sh -t <WMA_TAG> &
Have a nice day!

```

**NOTE:**
Currently, it is a must that only one WMAgent container should be running on a singe
agent VM. It is partially guarantied by setting the `--name=wmagent` parameter at
the `docker run` command above. But it is in fact possible to over come this by
setting a different name of the new container, but bare in mind all unpredictable
consequences of such action. If one tries tr start two containers with the same name,
the expected err is:
```
docker: Error response from daemon: Conflict. The container name "/wmagent" is already in use by container "c4c64688a75b6ac8f5cc5e4c951db324b2441ec1434f2e1d604a49d8009ff2a1". You have to remove (or rename) that container to be able to reuse that name.
See 'docker run --help'
```


## WMAgent Initialization process in details

### Main concept
The WMAgent needs to preserve its configuration and initialization data permanently
at the host. For the purpose, we use Host to Docker bind mounts. Once a specific
WMAgent image has been run for the first time it preserves a small set of `.init*` files
at `/data/dockerMount/srv/wmagent/<WMA_TAG>/config/` related to each initialization step.
On any further restart of the container, hence the WMAgent itself, we do not go through
all the steps again, but we rather check if the relevant `.init*` is present and the
`$WMA_BUILD_ID` hash contained there matches the `$WMA_BUILD_ID` of the currently starting container.
In order for one to enforce (re)initialization steps to be performed one needs to delete
all or part of the `.init*` files and restart the wmagent container.


Due to the architectural change that we introduce by splitting the agent's services
among different containers, we are now facing the potential thread of reusing an unclean
or broken database. Up until now we were wiping out the SQL database during
agent deployment (for both Mysql and Oracle - one deleted with the agent area
the other one by following an extra (manual) step during deployment).

Now we should start taking care of database integrity during WMAgent initialization.
In order to achieve that, in addition to the above initialization markers populated
at the host mount area, we also need to mark the SQL database
with the some meta data about the docker image and host which have initially created
the database. We also need to preserve a full SQL database schema as originally created.
All of this is realized in the next to next to final step just before uploading the agent's config
by creating the following meta data table in the `wmagnet` database, which is checked on agent start up.

```
[cmst1@unit02 wmagent]$ docker exec -it wmagent  bash
(WMAgent-2.2.3.2) [cmst1@unit02:current]$ manage db-prompt

MariaDB [wmagent]> select * from wma_init;
+--------------+------------------------------------------------------------------+
| initparam    | initvalue                                                        |
+--------------+------------------------------------------------------------------+
| wma_build_id | 7b7c7f3cc454ee1552dff4b10ece311f98e6a183c977978833e6ee7faff92974 |
| hostname     | unit02.cern.ch                                           |
| is_active    | true                                                             |
+--------------+------------------------------------------------------------------+
3 rows in set (0.001 sec)

```

### Implementation
The whole process as explained above, is implemented through four files:
* `run.sh` - just calls `init.sh` and goes into infinite loop in order to keep the container alive
* `init.sh` - takes care of all initialization and validation markers creation and keeping track of them, while the other
* `manage` - acts as a sole executor of management commands and only checks if a given management action is allowed or not.
* `manage-common.sh` - a file containing the definitions of all auxiliary variables and functions shared between `init.sh` and `manage` scripts


```
Docker entrypoint: run.sh

+--------------------+     +--------+     +------------------+
|    run.sh          | --> |init.sh | <-- | manage-common.sh |
| (goes to inf loop) |     |        |     +------------------+
+--------------------+     |        |                     /
                           |        |     +--------+     /
                           |        | --> | manage | <--+
                           |        |     | <Step> |
                           |        |     +--------+
                           |        | --> .init<Step>
                              ....
                           |        |
                           |        |     +--------+
                           |        | --> | manage |
                           |        |     | <Step> |
                           |        |     +--------+
                           |        | --> .init<Step>
                           +--------+

```



### List of initialization steps
The list of all steps performed during the first container start up is:
* Basic checks of minimal agent runtime requirements, such as mount points existence, environment file provided etc...
* Admin area checks - performing  `WMAgent.secrets` validation and loading it for the first time in order to estimate all configuration parameters, such as `AGENT_FLAVOR` etc.
* Tweaking Rucio config with runtime dependent values
* Activating the agent for the first time - this is the moment when we copy a configuration template for the first time in the agent, which is to be used for generating the proper WMAgent config file from WMAgent.secrets file later.
* Basic agent initialization - this is the moment when all the databases (SQL and Couch) are  created and populated
* Tweaking the WMAgent config file with all runtime dependent values (`hostname` etc.)
* Populating the agent's resource control - Adding all CMS sites and their resource definitions to the agent's database
* Marking the SQL database with the meta data about the image and host which have populated it, and creates a complete SQL database schema dump to be preserved at the host
* Uploading the wmagent configuration to central CouchDB
* Marking the agent as currently used in the system (Final step)


### List of all config/.init* files

The following is a list of all `.init*` files in order of setting

* config/.initAdmin - set once the admin area is checked (WMAgent is parsed, validated, and loaded)
* config/.initRucio - set once the Rucio config is tweaked reflecting the current agent's parameters (i.e. `agentType = prod|testbed`)
* config/.initActive - set once the agent has been activated for the first time (i.e. a fresh config template copied in the config area)
* config/.initAgent - set once the agent has been initialized for the first time with `manage init-agent` and fresh SQL and Couch databases have been created
* config/.initSqlDB - set once the metadata table `wma_init` has been recorded at the SQL database and a complete schema dump has been preserved at the host mount area
* config/.initCouchDB - set immediately after agent initialization
* config/.initConfig - set upon final WMAgent config file tweaks have been applied
* config/.initResourceControl - set once the resource control of the agent has been populated
* config/.initUpload - set once the agent config has been uploaded to central CouchDB
* config/.initUsing - Final init flag to mark that the agent is fully activated, initialized, and already in use by the system

### List of all related environment variables (with example values)

**NOTE:** All path related variables stem from `$WMA_ROOT_DIR`, there is only one
exception: `$WMA_DEPLOY_DIR`, which would differ for the cases when the wmagent
pypi package is to be installed with root or with `$WMA_USER` privileges:
* Installed by root: `WMA_DEPLOY_DIR=/usr/local`
* Installed by `$WMA_USER`: `WMA_DEPLOY_DIR=$WMA_BASE_DIR`


**NOTE:** There are 3 sets of variables needed for proper WMAgent initialization and running.
They are set at different moments along the process: i.e. at `buildtime` - when the Docker image is built, at `runtime` - when the container is run at the host and at `configtime` - manually setting them in the WMAgent.secrets file.

* **List of variables set at `buildtime` by Dockerfile:**

   * WMA_ADMIN_DIR=/data/admin/wmagent
   * WMA_AUTH_DIR=/data/srv/wmagent/2.2.3.2/auth/
   * WMA_BASE_DIR=/data/srv/wmagent
   * WMA_BUILD_ID=7b7c7f3cc454ee1552dff4b10ece311f98e6a183c977978833e6ee7faff92974
   * WMA_CERTS_DIR=/data/certs
   * WMA_CONFIG_DIR=/data/srv/wmagent/2.2.3.2/config
   * WMA_CURRENT_DIR=/data/srv/wmagent/2.2.3.2
   * WMA_DEPLOY_DIR=/usr/local
   * WMA_ENV_FILE=/usr/local/deploy/env.sh
   * WMA_GID=1399
   * WMA_GROUP=zh
   * WMA_INSTALL_DIR=/data/srv/wmagent/2.2.3.2/install
   * WMA_LOG_DIR=/data/srv/wmagent/2.2.3.2/logs
   * WMA_MANAGE_DIR=/data/srv/wmagent/2.2.3.2/config
   * WMA_ROOT_DIR=/data
   * WMA_SECRETS_FILE=/data/admin/wmagent/WMAgent.secrets
   * WMA_STATE_DIR=/data/srv/wmagent/2.2.3.2/state
   * WMA_TAG=2.2.3.2
   * WMA_UID=31961
   * WMA_USER=cmst1


* **List of variables set at `runtime` by sourcing `$WMA_ENV_FILE`:**

   * WMAGENT_SECRETS_LOCATION=$WMA_ROOT_DIR/admin/wmagent/WMAgent.secrets
   * X509_HOST_CERT=$WMA_CERTS_DIR/servicecert.pem
   * X509_HOST_KEY=$WMA_CERTS_DIR/servicekey.pem
   * X509_USER_CERT=$WMA_CERTS_DIR/servicecert.pem
   * X509_USER_KEY=$WMA_CERTS_DIR/servicekey.pem
   * X509_USER_PROXY=$WMA_CERTS_DIR/myproxy.pem
   * install=$WMA_INSTALL_DIR
   * config=$WMA_CONFIG_DIR
   * manage=$WMA_MANAGE_DIR/manage
   * RUCIO_HOME=$WMA_CONFIG_DIR
   * WMA_BUILD_ID=$(cat $WMA_ROOT_DIR/.wmaBuildId)
   * WMCORE_ROOT=$WMA_DEPLOY_DIR
   * WMAGENTPY3_ROOT=$WMA_INSTALL_DIR
   * WMAGENTPY3_VERSION=$WMA_TAG
   * CRYPTOGRAPHY_ALLOW_OPENSSL_102=true
   * YUI_ROOT=/usr/local/yui/
   * PATH=$WMA_INSTALL_DIR/bin${PATH:+:$PATH}
   * PATH=$WMA_DEPLOY_DIR/bin${PATH:+:$PATH}

* **List of variables set at `runtime` by sourcing `manage-common.sh` file:**
   * wmaInitAdmin=$WMA_CONFIG_DIR/.initAdmin
   * wmaInitAgent=$WMA_CONFIG_DIR/.initAgent
   * wmaInitActive=$WMA_CONFIG_DIR/.initActive
   * wmaInitUpload=$WMA_CONFIG_DIR/.initUpload
   * wmaInitConfig=$WMA_CONFIG_DIR/.initConfig
   * wmaInitResourceControl=$WMA_CONFIG_DIR/.initResourceControl
   * wmaInitCouchDB=$WMA_CONFIG_DIR/.initCouchDB
   * wmaInitSqlDB=$WMA_CONFIG_DIR/.initSqlDB
   * wmaInitRucio=$WMA_CONFIG_DIR/.initRucio
   * wmaInitUsing=$WMA_CONFIG_DIR/.initUsing
   * wmaSchemaFile=$WMA_CONFIG_DIR/.wmaSchemaFile.sql
   * wmaDBName=wmagent


* **List  of variables set at `configtime` defined in $WMAgent.secrets file:**

   * MDB_USER=*****
   * MDB_PASS=*****

    or

   * ORACLE_TNS=*****
   * ORACLE_USER=*****
   * ORACLE_PASS=*****


   * COUCH_USER=*****
   * COUCH_PASS=*****
   * COUCH_PORT=5984
   * COUCH_HOST=127.0.0.1
   * COUCH_CERT_FILE=/data/certs/servicecert.pem
   * COUCH_KEY_FILE=/data/certs/servicekey.pem
   * TEAMNAME=dev-unit02
   * GLOBAL_WORKQUEUE_URL=https://cmsweb-testbed.cern.ch/couchdb/workqueue
   * WMSTATS_URL=https://tivanov-unit02.cern.ch/couchdb/wmstats
   * REQMGR_URL=https://cmsweb-testbed.cern.ch/reqmgr/rest
   * ACDC_URL=https://cmsweb-testbed.cern.ch/couchdb/acdcserver
   * WORKLOAD_SUMMARY_URL=https://cmsweb-testbed.cern.ch/couchdb/workloadsummary
   * DBS3_URL=https://cmsweb-testbed.cern.ch/dbs/int/global/DBSWriter
   * PHEDEX_URL=https://cmsweb-testbed.cern.ch/phedex/datasvc/json/prod/
   * DQM_URL=https://cmsweb-testbed.cern.ch/dqm/dev
   * REQUESTCOUCH_URL=https://cmsweb-testbed.cern.ch/couchdb/reqmgr_workload_cache
   * REQMGR2_URL=https://cmsweb-testbed.cern.ch/reqmgr2
   * CENTRAL_LOGDB_URL=https://cmsweb-testbed.cern.ch/couchdb/wmstats_logdb
   * WMARCHIVE_URL=https://cmsweb-testbed.cern.ch/wmarchive
   * AMQ_CREDENTIALS=*****
   * GRAFANA_TOKEN=*****
   * RUCIO_ACCOUNT=wma_test
   * RUCIO_HOST=http://cms-rucio-int.cern.ch
   * RUCIO_AUTH=https://cms-rucio-auth-int.cern.ch
   * MSPILEUP_URL=https://cmsweb***.cern.ch/ms-pileup/data/pileup

## WMAgent operational actions
Basic operational actions, such as agent restarts, may be performed from the host by killing or starting the docker container.
At the same time, all agent management actions can be performed as usual from inside the container.

**NOTE:** No need for using `$` sign in front of the `manage` command any more!

**NOTE:** Once logged inside the container the command prompt will start with something like:

`(WMAgent-2.2.3.2) [cmst1@unit02:current]$`

### Checking container status

** Command from the host:**
```
ssh vocms****

docker container ps
CONTAINER ID   IMAGE             COMMAND                CREATED       STATUS       PORTS     NAMES
78d7e1baa3df   local/wmagent:2.2.3.2   "./run.sh -t 2.2.3.2"   2 hours ago   Up 2 hours             wmagent

```

### Connecting to the container

First login at the VM and from there connect to the container:

**Login sequence:**
```
[cmst1@unit02:current]$ docker exec -it wmagent bash

(WMAgent-2.2.3.2) [cmst1@unit02:current]$ manage status
```

### Starting the WMAgent container

**Starting command from the host:**
```
./wmagent-docker-run.sh -t <WMA_TAG> &
```

**Starting command from container:**
```
[cmst1@unit02:current]$ docker exec -it wmagent bash

(WMAgent-2.2.3.2) [cmst1@unit02:current]$ manage start-agent
Starting WMAgent...
Checking default database connection... ok.
Starting components: ['WorkQueueManager', 'DBS3Upload', 'JobAccountant', 'JobCreator', 'JobSubmitter', 'JobTracker', 'JobStatusLite', 'JobUpdater', 'ErrorHandler', 'RetryManager', 'JobArchiver', 'TaskArchiver', 'AnalyticsDataCollector', 'ArchiveDataReporter', 'AgentStatusWatcher', 'RucioInjector']
...
```


### Stopping the WMAgent container
In order to stop the WMAgent container one just needs to kill it. The `--rm` option at `docker run` commands (if used) assures we leave no leftover containers.

**Shutdown command from the host:**
```
docker kill wmagent
```

**Shutdown command from the container:**
```
[cmst1@unit02:current]$ docker exec -it wmagent bash

(WMAgent-2.2.3.2) [cmst1@unit02:current]$ manage stop-agent
Shutting down WMAgent...
Checking default database connection... ok.
Stopping components: ['WorkQueueManager', 'DBS3Upload', 'JobAccountant', 'JobCreator', 'JobSubmitter', 'JobTracker', 'JobStatusLite', 'JobUpdater', 'ErrorHandler', 'RetryManager', 'JobArchiver', 'TaskArchiver', 'AnalyticsDataCollector', 'ArchiveDataReporter', 'AgentStatusWatcher', 'RucioInjector']
...
```

### Enforce container (re)initialization at the host:

**NOTE:** The (re)initialization may result in losing previous job caches and database records**

**Initialization command from the host:**
```
[cmst1@unit02:current]$ docker kill wmagent

[cmst1@unit02:current]$ rm /data/dockerMount/srv/wmagent/<WMA_TAG>/config/.init*

[cmst1@unit02:current]$ ./wmagent-docker-run -t <WMA_TAG> &
```

**Initialization command from the container:**
```
[cmst1@unit02:current]$ docker exec -it wmagent bash

(WMAgent-2.2.3.2) [cmst1@unit02:current]$ rm /data/srv/wmagent/current/config/.init*
(WMAgent-2.2.3.2) [cmst1@unit02:current]$ /data/init.sh

```

### Cleaning an agent's database
**NOTE:** Any time one  restarts the agent's initialization or deploys a new agent
the previous database may still be present. As of now, we do not reuse old databases
from previous agents deployments, so it needs to be cleaned. The error which will be
shown during first agent start up in this case is:

```
(WMAgent-2.2.3.2) [cmst1@unit02:current]$ /data/init.sh

=======================================================
Starting WMAgent with the following initialisation data:
-------------------------------------------------------
 - WMAgent Version            : 2.2.3.2
 - WMAgent User               : cmst1
 - WMAgent Root path          : /data
...

-------------------------------------------------------
_check_mysql: Checking whether the MySQL server is reachable...
_status_of_mysql:
Uptime: 658075  Threads: 22  Questions: 131490  Slow queries: 0  Opens: 4186  Flush tables: 2  Open tables: 144  Queries per second avg: 0.199
_status_of_mysql: MySQL connection is OK!
_check_mysql: Checking whether the MySQL schema has been installed
_sql_db_isclean: Checking if the current SQL Database is clean and empty.
_sql_db_isclean: WARNING: numTables=49
_check_mysql: ERROR: Nonempty database. You may consider dropping it with 'manage clean-mysql'
ERROR: check_databases
```

You just need to follow the steps recommended from the error message and then restart the init process:
```
(WMAgent-2.2.3.2) [cmst1@unit02:current]$ manage clean-mysql
Dropping MySQL DB...
(WMAgent-2.2.3.2) [cmst1@unit02:current]$ /data/init.sh

=======================================================
Starting WMAgent with the following initialisation data:
-------------------------------------------------------
 - WMAgent Version            : 2.2.3.2
 - WMAgent User               : cmst1
 - WMAgent Root path          : /data
...

-------------------------------------------------------
Start: Performing checks for successful Docker initialisation steps...
WMA_BUILD_ID: 7b7c7f3cc454ee1552dff4b10ece311f98e6a183c977978833e6ee7faff92974
dockerInitId: 7b7c7f3cc454ee1552dff4b10ece311f98e6a183c977978833e6ee7faff92974
OK

Docker container has been initialised! However you still need to:
  1) Double check agent configuration: less /data/[dockerMount]/srv/wmagent/current/config/config.py
  2) Start the agent with one of the following commands:
     * From inside a running wmagent container:
       docker exec -it wmagent bash
       manage start-agent

     * From the host:
       docker kill wmagent
       ./wmagent-docker-run.sh -t <WMA_TAG> &
Have a nice day!
```

### Connecting to the agent's SQL database

One as usual may connect to the agents' database from inside the agent's  container:

**DB Prompt command from inside the container:**
```
(WMAgent-2.2.3.2) [cmst1@unit02:current]$ manage db-prompt
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 710
Server version: 5.5.68-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [wmagent]>
```
**NOTE:** There is no need for the redundant `wmagent` parameter when connecting
a MariaDB node. So the db-prompt command now is the same for both MySQL and Oracle connections.

### Executing specific/individual auxiliary functions (not steps) from the initialization logic

For some debugging purposes, one may want to inspect what is going on in any of
the auxiliary functions defined for both `manage` and `init.sh` scripts.
(e.g. `_renew_proxy` or inspecting the output from executing a direct database
command with `_exec_mysql` etc...)

This operation is as simple as following these 3 steps:
* source the file with common definitions
* load the `WMAgent.Secrets` file
* execute the command you wish

**Command to execute any auxiliary function from inside the container:**
```
(WMAgent-2.2.3.2) [cmst1@unit02:current]$ source $WMA_DEPLOY_DIR/bin/manage-common.sh
(WMAgent-2.2.3.2) [cmst1@unit02:current]$ _load_wmasecrets
(WMAgent-2.2.3.2) [cmst1@unit02:current]$ _exec_mysql "select * from wma_init;" wmagent

wma_build_id	7b7c7f3cc454ee1552dff4b10ece311f98e6a183c977978833e6ee7faff92974
hostname	unit02.cern.ch
is_active	true

(WMAgent-2.2.3.2) [cmst1@unit02:current]$
(WMAgent-2.2.3.2) [cmst1@unit02:current]$ _renew_proxy

_renew_proxy: Checking Certificate lifetime:
_renew_proxy: Certificate end date: Sep  7 12:04:12 2023 GMT
_renew_proxy: WARNING: The service certificate lifetime is less than certMinLifetimeHours: 168! Please update it ASAP!
_renew_proxy: Checking myproxy lifetime:
_renew_proxy: myproxy end date: Sep  6 12:44:15 2023 GMT
...
Creating proxy ..................................................... Done


Warning: your certificate and proxy will expire Wed Sep  6 12:44:15 2023
which is within the requested lifetime of the proxy
_renew_proxy: ERROR: Failed to renew invalid myproxy

```
