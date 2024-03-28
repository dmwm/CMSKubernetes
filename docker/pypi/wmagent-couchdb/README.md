# Couchdb default image for running wmagent

## Prerequisites

This image inherits from the mainstream `couchdb` one, and follows the same
tagging schema. On top of the base `couchdb` image we add all the structure
needed for running the WMAgent with CouchDB and two main scripts:

* `couchdb-docker-run.sh`
* `couchdb-docker-build.sh`

For building the containers, and for creating the mount area at the host and the
the bind mounts inside the container, respectively. Those are as follows:

* At the host:

```
/data/dockerMount/{admin|srv}/couchdb
```

* At the container:

```
/data/{admin|srv}/couchdb
```

Upon starting the container we try to initialize the default user and system
databases, which if previously created should exist in the host mount area.

There are no other external dependencies.

We fetch all the passwords from two secrets files (giving the container-based paths below, which map to `/data/dockerMount/{wmagent|couchdb}` in the host):

* `/data/admin/wmagent/WMAgent.secrets` - for reading the credentials of the
  user to be used by the WMAgent to connect to the database

## Usage

### Building CouchDB image

We can build everything locally and upload it at the CERN registry: https://registry.cern.ch

* Using the wrapper script to build CouchDB locally:
```
$ ssh vocms****
user@vocms0290:wmagent-couchdb $ cd /data
user@vocms0290:wmagent-couchdb $ git clone https://github.com/dmwm/CMSKubernetes.git
user@vocms0290:wmagent-couchdb $ cd /data/CMSKubernetes/docker/pypi/wmagent-couchdb/
user@vocms0290:wmagent-couchdb $ ./couchdb-docker-build.sh -t 3.2.2

user@vocms0290:wmagent-couchdb $ docker image  ls
REPOSITORY                                        TAG       IMAGE ID       CREATED         SIZE
local/couchdb                                     3.2.2     2ec9e59aa0e9   1 minute ago     819MB
```
* Using the wrapper script to build and upload CouchDB to registry.cern.ch:
```
./couchdb-docker-build.sh -t 3.2.2 -p
```

### Running a CouchDB container

We can run from the local repository or from upstream CERN registry.

* Running from a local build:

```
cmst1@vocms0290:wmagent-couchdb $ ./couchdb-docker-run.sh -t 3.2.2
Starting the couchdb:3.2.2 docker container with the following parameters:  --user cmst1
8decd12e153d74c9de48764b8d3faf975d7d52897c5b0fc1032e6fef7a7c74dd

cmst1@vocms0290:wmagent-couchdb $ docker ps
CONTAINER ID   IMAGE                             COMMAND           CREATED          STATUS          PORTS     NAMES
8decd12e153d   local/couchdb:3.2.2               "./run.sh"        12 seconds ago   Up 11 seconds             couchdb
```

* Running from CERN registry:
```
cmst1@vocms0290:wmagent-couchdb $ ./couchdb-docker-run.sh -t 3.2.2 -p
Pulling Docker image: registry.cern.ch/cmsweb/cdb:3.2.2
3.2.2: Pulling from cmsweb/couchdb
Digest: sha256:61f798b55a1c743686e1568509975308dc07b5b24486894053d6a312983c4af6
Status: Downloaded newer image for registry.cern.ch/cmsweb/couchdb:3.2.2
registry.cern.ch/cmsweb/couchdb:3.2.2
Starting the couchdb:3.2.2 docker container with the following parameters:  --user cmst1
21d9c6598f35e627834d1b796460047605d6255cebc746d572289c7b418053ed

cmst1@vocms0290:wmagent-couchdb $ docker ps
CONTAINER ID   IMAGE                             COMMAND      CREATED         STATUS         PORTS     NAMES
21d9c6598f35   registry.cern.ch/couchdb:3.2.2   "./run.sh"   7 seconds ago   Up 6 seconds             couchdb

```

* Killing the container directly from the host:
```
cmst1@vocms0290:wmagent-couchdb $ docker kill couchdb
couchdb

```

* Connecting to a running container:
```
cmst1@vocms0290:wmagent-couchdb $ docker exec -it couchdb bash
(CouchDB-3.2.2) [cmst1@vocms0290:data]$

```

* Fetching startup logs:
```
cmst1@vocms0265:wmagent-couchdb $ docker logs couchdb
ME : data
TOP : /
ROOT : /
CFGDIR : /data/srv/couchdb/3.2.2/config
LOGDIR : /data/srv/couchdb/3.2.2/logs
STATEDIR : /data/srv/couchdb/3.2.2/state
KEYFILE : /data/srv/couchdb/auth//hmackey.ini

COUCH_ROOT_DIR : /data
COUCH_BASE_DIR : /data/srv/couchdb
COUCH_STATE_DIR : /data/srv/couchdb/3.2.2/state
COUCH_INSTALL_DIR : /data/srv/couchdb/3.2.2/install
COUCH_CONFIG_DIR : /data/srv/couchdb/3.2.2/config
<snip>
Installing WorkQueue app into database: http://localhost:5984/workqueue
Installing WorkQueue app into database: http://localhost:5984/workqueue_inbox
start sleeping....zzz
```

### Managing the database service:

All of the commands bellow must be run from inside the container.

* General options:
```
(CouchDB-3.2.2) [cmst1@vocms0290:data]$ manage help

Usage: manage ACTION [ARG] [SECURITY-STRING]

Available actions:
  help            show this help
  version         get current version of the service
  status          show current service's status
  sysboot         start server from crond if not running
  restart         (re)start the service
  start           (re)start the service
  stop            stop the service
  pushapps        push couch applications
  pushreps        push couch replications
  updatecouchapps pull new couch applications from WMCore repo
  compact         compact database ARG
  compactviews    compact database views for design doc ARG ARG
  cleanviews      clean view named ARG
  backup          rsync databases to ARG (i.e. [user@]host:path)
  archive         archive backups to ARG area in castor

For more details please refer to operations page:
  https://twiki.cern.ch/twiki/bin/view/CMS/CouchDB

```

* Start/Stop the database server:
```
(CouchDB-3.2.2) [cmst1@vocms0290:data]$ manage start
ME : 3.2.2
TOP : /data
ROOT : /data/srv
CFGDIR : /data/srv/couchdb/3.2.2/config
LOGDIR : /data/srv/couchdb/3.2.2/logs
STATEDIR : /data/srv/couchdb/3.2.2/state
KEYFILE : /data/srv/couchdb/auth//hmackey.ini

COUCH_ROOT_DIR : /data
COUCH_BASE_DIR : /data/srv/couchdb
COUCH_STATE_DIR : /data/srv/couchdb/3.2.2/state
COUCH_INSTALL_DIR : /data/srv/couchdb/3.2.2/install
COUCH_CONFIG_DIR : /data/srv/couchdb/3.2.2/config

Which couchdb: /opt/couchdb/bin/couchdb
  With configuration directory: /data/srv/couchdb/3.2.2/config
  With logdir: /data/srv/couchdb/3.2.2/logs
  nohup couchdb -couch_ini /data/srv/couchdb/3.2.2/config >> /data/srv/couchdb/3.2.2/logs/couch.log 2>&1 &

```


* Pushing new couch applications:
 
```
(CouchDB-3.2.2) [cmst1@vocms0265:data]$ manage pushapps
ME : 3.2.2
TOP : /data
ROOT : /data/srv
CFGDIR : /data/srv/couchdb/3.2.2/config
LOGDIR : /data/srv/couchdb/3.2.2/logs
STATEDIR : /data/srv/couchdb/3.2.2/state
KEYFILE : /data/srv/couchdb/auth//hmackey.ini

COUCH_ROOT_DIR : /data
COUCH_BASE_DIR : /data/srv/couchdb
COUCH_STATE_DIR : /data/srv/couchdb/3.2.2/state
COUCH_INSTALL_DIR : /data/srv/couchdb/3.2.2/install
COUCH_CONFIG_DIR : /data/srv/couchdb/3.2.2/config

Installing ACDC app into database: http://localhost:5984/acdcserver
Installing GroupUser app into database: http://localhost:5984/acdcserver
Installing ReqMgrAux app into database: http://localhost:5984/reqmgr_auxiliary
Installing ReqMgr app into database: http://localhost:5984/reqmgr_workload_cache
Installing ConfigCache app into database: http://localhost:5984/reqmgr_config_cache
Installing WorkloadSummary app into database: http://localhost:5984/workloadsummary
Installing LogDB app into database: http://localhost:5984/wmstats_logdb
Installing WMStats app into database: http://localhost:5984/wmstats
Installing WMStatsErl app into database: http://localhost:5984/wmstats
Installing WMStatsErl1 app into database: http://localhost:5984/wmstats
Installing WMStatsErl2 app into database: http://localhost:5984/wmstats
Installing WMStatsErl3 app into database: http://localhost:5984/wmstats
Installing WMStatsErl4 app into database: http://localhost:5984/wmstats
Installing WMStatsErl5 app into database: http://localhost:5984/wmstats
Installing WMStatsErl6 app into database: http://localhost:5984/wmstats
Installing WMStatsErl7 app into database: http://localhost:5984/wmstats
Installing T0Request app into database: http://localhost:5984/t0_request
Installing WorkloadSummary app into database: http://localhost:5984/t0_workloadsummary
Installing LogDB app into database: http://localhost:5984/t0_logdb
Installing WMStats app into database: http://localhost:5984/tier0_wmstats
Installing WMStatsErl app into database: http://localhost:5984/tier0_wmstats
Installing WMStatsErl1 app into database: http://localhost:5984/tier0_wmstats
Installing WMStatsErl2 app into database: http://localhost:5984/tier0_wmstats
Installing WMStatsErl3 app into database: http://localhost:5984/tier0_wmstats
Installing WMStatsErl4 app into database: http://localhost:5984/tier0_wmstats
Installing WMStatsErl5 app into database: http://localhost:5984/tier0_wmstats
Installing WMStatsErl6 app into database: http://localhost:5984/tier0_wmstats
Installing WMStatsErl7 app into database: http://localhost:5984/tier0_wmstats
Installing WorkQueue app into database: http://localhost:5984/workqueue
Installing WorkQueue app into database: http://localhost:5984/workqueue_inbox

```

* Pushing new couch replications

```
(CouchDB-3.2.2) [cmst1@vocms0265:data]$ manage pushreps
ME : 3.2.2
TOP : /data
ROOT : /data/srv
CFGDIR : /data/srv/couchdb/3.2.2/config
LOGDIR : /data/srv/couchdb/3.2.2/logs
STATEDIR : /data/srv/couchdb/3.2.2/state
KEYFILE : /data/srv/couchdb/auth//hmackey.ini

COUCH_ROOT_DIR : /data
COUCH_BASE_DIR : /data/srv/couchdb
COUCH_STATE_DIR : /data/srv/couchdb/3.2.2/state
COUCH_INSTALL_DIR : /data/srv/couchdb/3.2.2/install
COUCH_CONFIG_DIR : /data/srv/couchdb/3.2.2/config
```

* Pulling new applications from WMCore repo

```
(CouchDB-3.2.2) [cmst1@vocms0290:data]$ manage updatecouchapps 2.3.0
ME : 3.2.2
TOP : /data
ROOT : /data/srv
CFGDIR : /data/srv/couchdb/3.2.2/config
LOGDIR : /data/srv/couchdb/3.2.2/logs
STATEDIR : /data/srv/couchdb/3.2.2/state
KEYFILE : /data/srv/couchdb/auth//hmackey.ini

COUCH_ROOT_DIR : /data
COUCH_BASE_DIR : /data/srv/couchdb
COUCH_STATE_DIR : /data/srv/couchdb/3.2.2/state
COUCH_INSTALL_DIR : /data/srv/couchdb/3.2.2/install
COUCH_CONFIG_DIR : /data/srv/couchdb/3.2.2/config

/data/srv/couchdb/3.2.2/install/stagingarea/tmp /data

Pulling couchapps version 2.3.0 from Github...
2024-03-13 12:45:01 URL:https://codeload.github.com/dmwm/WMCore/tar.gz/refs/tags/2.3.0 [11592963] -> "2.3.0.tar.gz" [1]

Pulling additional reqmon and t0_reqmon dependencies...

Downloading jquery-ui.min.js...
2024-03-13 12:45:02 URL:https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.18/jquery-ui.min.js [201842/201842] -> "jquery-ui.min.js" [1]

Downloading jquery.min.js...
2024-03-13 12:45:02 URL:http://code.jquery.com/jquery-1.7.2.min.js [94840/94840] -> "jquery-1.7.2.min.js" [1]

Downloading Datatables...
2024-03-13 12:45:02 URL:https://datatables.net/releases/DataTables-1.9.1.zip [2415658/2415658] -> "DataTables-1.9.1.zip" [1]

Downloading YUI...
2024-03-13 12:45:03 URL:https://yui.github.io/yui2/archives/yui_2.9.0.zip [14294111/14294111] -> "yui_2.9.0.zip" [1]
/data/srv/couchdb/3.2.2/install/stagingarea/tmp/yui /data/srv/couchdb/3.2.2/install/stagingarea/tmp /data
/data/srv/couchdb/3.2.2/install/stagingarea/tmp /data
Removing old couchapps...
Installing new couchapps...
/data
Cleaning up!
```


