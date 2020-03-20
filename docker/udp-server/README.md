### CMSSW UDP collector service
The new CMSSW UDP collector service consist of UDP server `udp_server`
and `udp_server_monitor` executables. These programs area available
from CMSKubernetes repository, see [1]. They should be compiled on
lxplus in the following way:
```
# login to lxplus
ssh lxplus

# obtain go source, e.g.
curl -kO https://raw.githubusercontent.com/dmwm/CMSKubernetes/master/docker/udp-server/udp_server.go
curl -kO https://raw.githubusercontent.com/dmwm/CMSKubernetes/master/docker/udp-server/udp_server_monitor.go

# build executables
go build udp_server.go
go build udp_server_monitor.go
```

### Service maintenance
To start the service please compiled and download `udp_server` and `udp_server_monitor`
executables to your node and start it as following:
```
# create your udp_server.json file, please provide proper credentials
cat > udp_server.json << EOF
{
    "port": 9331,
    "bufSize": 1024,
    "stompURI": "",
    "endpoint": "",
    "contentType": "application/json",
    "verbose": false
}
EOF
# make sure that PATH contains path to location of your executable, e.g.
export PATH=$PATH:$PWD
# start udp_server_monitor process which will take care of udp_server
nohup ./udp_server_monitor 2>&1 1>& log < /dev/null &
```

### References
1. https://github.com/dmwm/CMSKubernetes/tree/master/docker/udp-server
