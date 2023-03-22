# cmsmon-alerts

Base image for many Go services. Build by GH actions : [CMSMonitoring/../build-go-tools.yml](https://github.com/dmwm/CMSMonitoring/blob/master/.github/workflows/build-go-tools.yml)

### How to test

Example distro-less test for es-exporter-wma

```
# Because docker image is distroless and we cannot kill and restart a process, ..
#  .. we need to add required secret while building the image to test

# Add below line to final stage
ADD [LOCAL]/secrets/es-exporter/token /etc/secrets/token

# Build docker image
docker build -t cmsmon-alerts-test .

# Check help message of go service
docker run -it cmsmon-alerts-test /data/es_exporter --help

# Run es-expoerter-wma in host network
docker run -it --network host cmsmon-alerts-test \
    /data/es_exporter -dbname WMArchive \
    -token /etc/secrets/token -namespace "http" -port ":18000" -verbose 3

# Curl in another shell
curl localhost:18000/metrics

# See prometheus metrics. Important one is to see "wmarchive 200"
   # HELP es_monit_prod_wmarchive_status Current status of monit_prod_wmarchive
   # TYPE es_monit_prod_wmarchive_status counter
   es_monit_prod_wmarchive_status 200
```
