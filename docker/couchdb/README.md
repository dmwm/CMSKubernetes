### CouchDB image construction
Image is built with the expected `_couchdb` user, also used to run the service.
* latest version has been tagged as `3.2.2-stable`.
* **configuration**: available under `/data/srv/auth/couchdb/`,
* **database**: both database and views are available under `/data/srv/state/couchdb/database/`.
* **couchapps**: couchapps libraries and code is available under `/data/srv/state/couchdb/stagingarea/`.
* **logs**: finally, service logs can be found at `/data/srv/logs/couchdb/`.

### Run CouchDB container
Connect to the cmsweb backend VM with the cmsweb account and:
```
cd /data/srv
curl https://raw.githubusercontent.com/dmwm/CMSKubernetes/master/docker/couchdb/docker-run.sh > docker-run.sh
chmod +x docker-run.sh 
./docker-run.sh

```

### Stop CouchDB container
Connect to the cmsweb backend VM with the cmsweb account and:
```
docker stop couchdb
docker rm couchdb //it is best to do it with [docker-run.sh](https://raw.githubusercontent.com/dmwm/CMSKubernetes/2857afd72352e08d1ee34f7af9b06141ec811835/docker/couchdb/docker-run.sh) script which sets up the environment variables
```

### Checking status of CouchDB service
```
docker exec -it couchdb sh -c "/data/srv/current/config/couchdb/manage status"
```

## Rotate CouchDB logs

Ideally, this procedure should be done once every month. We also have a Prometheus alert that comes from the following [configuration](https://its.cern.ch/jira/browse/CMSMONIT-673) -- when the storage reaches 80%, cmsweb-operator and cms-wmcore-team e-groups get the alerts.

### Preparation
```
cd /data/srv/
rm -f docker-run.sh 
wget -nv https://raw.githubusercontent.com/dmwm/CMSKubernetes/2857afd72352e08d1ee34f7af9b06141ec811835/docker/couchdb/docker-run.sh
chmod +x docker-run.sh
ll
```

### Execution
```
ls -ltha /data/srv/logs/couchdb/
docker ps
docker stop -t 60 couchdb
docker rm couchdb
docker ps --all
docker pull registry.cern.ch/cmsweb/couchdb:3.2.2-stable
docker image ls
sudo chown -R cmsweb:zh /data/srv/logs/couchdb
tail -n100000 /data/srv/logs/couchdb/couch.log >  /data/srv/logs/couchdb/couchnew.log && mv /data/srv/logs/couchdb/couchnew.log /data/srv/logs/couchdb/couch.log
ls -ltha /data/srv/logs/couchdb/
./docker-run.sh
```



### Post checks
```
docker ps
curl localhost:5984/_all_dbs
```

