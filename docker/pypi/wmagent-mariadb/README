# MariaDB default image for running WMAgent

## Prerequisites

This image inherits from the mainstream `mariadb` one, and follows the same
tagging schema. On top of the base `mariadb` image we add all the structure
needed for running the WMAgent with MariaDB and two main scripts:

* `mariadb-docker-run.sh`
* `mariadb-docker-build.sh`

For building the containers, and for creating the mount area at the host and the
the bind mounts inside the container, respectively. Those are as follows:

* At the host:
```
/data/dockerMount/{admin|srv}/mariadb
```
* At the container:

```
/data/{admin|srv}/mariadb
```

Upon starting the container we try to initialize the default user and system
databases, which if previously created should exist in the host mount area. And
the last steps are creating the `wmagent` database.

There are no other external dependencies.

We fetch all the passwords from two secrets files:

* `/data/admin/wmagent/WMAgent.secrets` - for reading the credentials for the
  user to be used by the WMAgent to connect to the datbase
* `/data/admin/mariadb/MariaDB.secrets` - for reading the the credentials for
    the root user who is about to have full administrative rights on the MariaDB
    server
    **NOTE:** The server admin user configured at the `MariaDB.secrets` file,
        must match the username of the one who is to run the server inside the
        container. And the later is resolved at runtime, depending on where we
        run the container, it could be on of the three:
   * CERN - production agent
   * CERN - T0 agent
   * FNAL

## Usage

### Building MariaDB image

We can build everything locally and upload it at the CERN registry: https://registry.cern.ch

* Using the wrapper script to build MariaDB locally:
```
$ ssh vocms****
user@vocms0290:wmagent-mariadb $ cd /data
user@vocms0290:wmagent-mariadb $ git clone https://github.com/dmwm/CMSKubernetes.git
user@vocms0290:wmagent-mariadb $ cd /data/CMSKubernetes/docker/pypi/wmagent-mariadb/
user@vocms0290:wmagent-mariadb $ ./mariadb-docker-build.sh -t 10.6.5

user@vocms0290:wmagent-mariadb $ docker image  ls
REPOSITORY                 TAG       IMAGE ID       CREATED          SIZE
local/mariadb              10.6.5    4efa646aea3e   6 minutes ago    950MB
local/mariadb              latest    4efa646aea3e   6 minutes ago    950MB
```
* Using the wrapper script to build and upload MariaDB to registry.cern.ch:
```
./mariadb-docker-build.sh -t 10.6.5 -p
```

### Running a MariaDB container

We can run from local repository or from upstream CERN registry. The set of
images one may end up working may look like:

```
cmst1@vocms0290:wmagent-mariadb $ docker image  ls
REPOSITORY                 TAG       IMAGE ID       CREATED          SIZE
local/mariadb              10.6.5    4efa646aea3e   6 minutes ago    950MB
local/mariadb              latest    4efa646aea3e   6 minutes ago    950MB
registry.cern.ch/mariadb   10.6.5    8539e03b7a1d   21 minutes ago   950MB
registry.cern.ch/mariadb   latest    8539e03b7a1d   21 minutes ago   950MB
```

* Running from a local build:

```
cmst1@vocms0290:wmagent-mariadb $ ./mariadb-docker-run.sh -t 10.6.5
Starting the mariadb:10.6.5 docker container with the following parameters:  --user cmst1
eb7e0d879d4d7fa597587c734837c5289886a6aaf6a82c072187371fdf312b90

cmst1@vocms0290:wmagent-mariadb $ docker ps
CONTAINER ID   IMAGE                  COMMAND      CREATED         STATUS         PORTS     NAMES
eb7e0d879d4d   local/mariadb:10.6.5   "./run.sh"   3 seconds ago   Up 2 seconds             mariadb
```

* Running from CERN registry:
```
cmst1@vocms0290:wmagent-mariadb $ ./mariadb-docker-run.sh -t 10.6.5 -p
Pulling Docker image: registry.cern.ch/cmsweb/mariadb:10.6.5
10.6.5: Pulling from cmsweb/mariadb
Digest: sha256:61f798b55a1c743686e1568509975308dc07b5b24486894053d6a312983c4af6
Status: Downloaded newer image for registry.cern.ch/cmsweb/mariadb:10.6.5
registry.cern.ch/cmsweb/mariadb:10.6.5
Starting the mariadb:10.6.5 docker container with the following parameters:  --user cmst1
21d9c6598f35e627834d1b796460047605d6255cebc746d572289c7b418053ed

cmst1@vocms0290:wmagent-mariadb $ docker ps
CONTAINER ID   IMAGE                             COMMAND      CREATED         STATUS         PORTS     NAMES
21d9c6598f35   registry.cern.ch/mariadb:10.6.5   "./run.sh"   7 seconds ago   Up 6 seconds             mariadb

```

* Killing the container directly from the host:
```
cmst1@vocms0290:wmagent-mariadb $ docker kill mariadb
mariadb

```

* Connecting to a running container:
```
cmst1@vocms0290:wmagent-mariadb $ docker exec -it mariadb bash
(MariaDB-10.6.5) [cmst1@vocms0290:data]$

```

* Managing the databse service:
    * General options:
```
(MariaDB-10.6.5) [cmst1@vocms0290:data]$ manage --help

The manage script of the MariaDB docker image for WMAgent

Usage: manage  status | start-mariadb | stop-mariadb | clean-mariadb | db-prompt | version

```
    * Stat/Stop the database:
```
(MariaDB-10.6.5) [cmst1@vocms0290:data]$ manage start-mariadb
start_mariadb: Starting MariaDB server
...
240301 09:25:54 mysqld_safe Can't log to error log and syslog at the same time.  Remove all --log-error configuration options for --syslog to take effect.
240301 09:25:54 mysqld_safe Logging to '/data/srv/mariadb/10.6.5/logs/error.log'.
240301 09:25:54 mysqld_safe Starting mariadbd daemon with databases from /data/srv/mariadb/10.6.5/install/database
mariadb-admin  Ver 9.1 Distrib 10.6.5-MariaDB, for debian-linux-gnu on x86_64
Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Server version		10.6.5-MariaDB-1:10.6.5+maria~focal-log
Protocol version	10
Connection		Localhost via UNIX socket
UNIX socket		/var/run/mysqld/mariadb.sock
Uptime:			10 sec

Threads: 2  Questions: 1  Slow queries: 0  Opens: 16  Open tables: 10  Queries per second avg: 0.100

```
If one tries to start a second server on the same socket:
```
(MariaDB-10.6.5) [cmst1@vocms0290:data]$ manage start-mariadb
start_mariadb: WARNING: MariaDB Server already running on --socket=/var/run/mysqld/mariadb.sock

```
    * Cleaning the WMAgent database:
```
(MariaDB-10.6.5) [cmst1@vocms0290:data]$ manage clean-mariadb

clean_mariadb: THE CURRENT OPERATIONS WILL WIPE OUT THE wmagent DATABASE.
clean_mariadb: Continue? [n]: y
clean_mariadb: ...
clean_mariadb: You still have 5 sec. to cancel before we proceed.

clean_mariadb: DROPPING wmagent DATABASE!

```

    * Connecting to the database with the admin user locally from inside the container:
```
(MariaDB-10.6.5) [cmst1@vocms0290:data]$ manage db-prompt
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 5
Server version: 10.6.5-MariaDB-1:10.6.5+maria~focal-log mariadb.org binary distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [wmagent]>
```

    * Fetching startup logs:
```
cmst1@vocms0290:wmagent-mariadb $ docker  logs mariadb
-------------------------------------------------------------------------
Stopping any previously running mariadb server
mariadb-admin: connect to server at 'localhost' failed
error: 'Can't connect to local MySQL server through socket '/data/srv/mariadb/10.5/mariadb.sock' (2)'
Check that mysqld is running and that the socket: '/data/srv/mariadb/10.5/mariadb.sock' exists!

-------------------------------------------------------------------------
Trying to install system database if it is not present already
mysql.user table already exists! Run mysql_upgrade, not mysql_install_db
WARNING: System and user databases already exist. NOT trying to create them.
starting MariaDB server
...
240226 18:24:13 mysqld_safe Logging to '/data/srv/mariadb/10.5/logs/error.log'.
240226 18:24:13 mysqld_safe Starting mariadbd daemon with databases from /data/srv/mariadb/10.5/install/database
mariadb-admin  Ver 9.1 Distrib 10.5.24-MariaDB, for debian-linux-gnu on x86_64
Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Server version		10.5.24-MariaDB-1:10.5.24+maria~ubu2004-log
Protocol version	10
Connection		Localhost via UNIX socket
UNIX socket		/data/srv/mariadb/10.5/mariadb.sock
Uptime:			10 sec

Threads: 1  Questions: 1  Slow queries: 0  Opens: 16  Open tables: 10  Queries per second avg: 0.100

Uptime: 10  Threads: 1  Questions: 2  Slow queries: 0  Opens: 16  Open tables: 10  Queries per second avg: 0.200

Start sleeping....zzz
```