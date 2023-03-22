# http-exporter

### How to build

```
docker_registry=registry.cern.ch/cmsmonitoring
image_tag=20230321
docker build -t "${docker_registry}/http-exporter:${image_tag}" .
# push
docker push "${docker_registry}/http-exporter:${image_tag}"
```

### How to test: simple http-exporter (queries cms-monitoring) 

Example distro-less test for http-exporter simple service which queries cms-monitoring. No secret required.

```
# Build docker image
docker build -t test-http-exporters .

# Check help message of go service
docker run -it test-http-exporters /data/http_exporter --help

# Run http-expoerter in host network
docker run -it --network host test-http-exporters /data/http_exporter \
    -uri "http://cms-monitoring.cern.ch:30900/graph" \
    -namespace "cms_monitoring" -port ":18000" -agent "monitoring" -verbose 3

# Curl in another shell
curl localhost:18000/metrics

# See prometheus metrics. Important one is to see "cms_monitoring_status 200"
   # HELP cms_monitoring_status Current status of http://cms-monitoring.cern.ch:30900/graph
    # TYPE cms_monitoring_status counter
    cms_monitoring_status 200
```

### How to test: with proxy secrets (cric)

Example distro-less test for http-exporter simple service which queries CRIC. proxy secret is required.

```
# Because docker image is distroless and we cannot kill and restart a process, ..
#  .. we need to add required secret while building the image to test

# Add below lines to final stage for proxy secret. You can create proxy file with (voms command)
ADD proxy /etc/proxy/proxy
ENV X509_USER_PROXY=/etc/proxy/proxy

# Run http-expoerter in host network
docker run -it --network host test-http-exporters /data/http_exporter \
    -uri "https://cms-cric.cern.ch/api/cms/site/query/?json&preset=data-processing" \
     -namespace "cric" -port ":18004" -agent "monitoring" -verbose 2

# Curl in another shell
curl localhost:18004/metrics

# See prometheus metrics. Important one is to see "cric_status 200"
    # TYPE cric_status counter
    cric_status 200
```
