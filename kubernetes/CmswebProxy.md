# clone deployment cfg
git clone -n git://github.com/dmwm/deployment.git cfg --depth 1
cd cfg
git checkout HEAD admin/ProxyRenew
git checkout HEAD admin/ProxySeed

mkdir proxy
admin/ProxySeed -t dev -d $PWD/proxy

# settings
login=cmsweb-k8s_$(id -un)

# create proxy on myproxy
export GT_PROXY_MODE="rfc"
myproxy-init -x -R "/DC=ch/DC=cern/OU=Organic Units/OU=Users/CN=cmswebmi/CN=657477/CN=Robot: CMS Web Service account" -c 720 -t 36 -s myproxy.cern.ch -l $login

sudo myproxy-init -x -R "/DC=ch/DC=cern/OU=Organic Units/OU=Users/CN=cmswebmi/CN=657477/CN=Robot: CMS Web Service account" -c 720 -t 36 -s myproxy.cern.ch -l cmsweb-k8s --certfile /etc/secrets/server.crt --keyfile /etc/secrets/server.key

# renew myproxy
admin/ProxyRenew /data/certs $PWD/proxy $login cms

sudo voms-proxy-init -voms cms -rfc --cert /etc/secrets/server.crt --key /etc/secrets/server.key
sudo myproxy-init -x -R "/DC=ch/DC=cern/OU=Organic Units/OU=Users/CN=cmswebmi/CN=657477/CN=Robot: CMS Web Service account" -c 720 -t 36 -s myproxy.cern.ch -l cmsweb-k8s --certfile /etc/secrets/server.crt --keyfile /etc/secrets/server.key

myproxy-get-delegation -q -t 36 -l $login -a "$proxy" -o "$proxy.new"
grid-proxy-info -file "$proxy.new" -exists -valid $h:$m
