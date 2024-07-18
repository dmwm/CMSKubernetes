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
docker rm couchdb
```

### Checking status of CouchDB service
```
docker exec -it couchdb sh -c "/data/srv/current/config/couchdb/manage status"
```
