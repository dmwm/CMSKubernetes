#!/bin/bash
# script to start MSUnmerged


### Usage: Usage: run.sh [-e 'RSE Expression']
### Usage:
### Usage:   -e  <RSE Expression>   A Rucio RSE Expression to be passed to the service configuration
### Usage:                          before service start
### Usage:   -h <help>              Provides help to the current script
### Usage:
### Usage: Example: ./run.sh -e 'rse_type=DISK&country=US&tier=3&cms_type=real'
### Usage: Example: ./run.sh
### Usage:

FULL_SCRIPT_PATH="$(realpath "${0}")"

usage()
{
    echo -e $*
    grep '^### Usage:' < $FULL_SCRIPT_PATH
    exit 1
}

help()
{
    echo -e $*
    grep '^### Usage:' < $FULL_SCRIPT_PATH
    exit 0
}

### Searching for the mandatory and optional arguments:
# export OPTIND=1
while getopts ":e:h" opt; do
    case ${opt} in
        e)
            rseExpr=${OPTARG}
            # escaping all possible special characters in the RSE expression:
            # NOTE: One should always start escaping the escaping chars first
            rseExpr=${rseExpr//\\/\\\\}
            rseExpr=${rseExpr//&/\\&}
            rseExpr=${rseExpr//|/\\|}
            ;;
        h)
            help
            ;;
        \? )
            msg="Invalid Option: -$OPTARG"
            usage "$msg"
            ;;
        : )
            msg="Invalid Option: -$OPTARG requires an argument"
            usage "$msg"
            ;;
    esac
done


srv=`echo $USER | sed -e "s,_,,g"`
STATEDIR=/data/srv/state/$srv
LOGDIR=/data/srv/logs/$srv
AUTHDIR=/data/srv/current/auth/$srv
CONFIGDIR=/data/srv/current/config/$srv
CONFIGFILE=${CONFIGFILE:-config.py}
CFGFILE=/etc/secrets/$CONFIGFILE

### permission update to workaround issues with mounting logs volume
sudo chown -R $USER.$USER /data

mkdir -p $LOGDIR
mkdir -p $STATEDIR
mkdir -p $AUTHDIR
mkdir -p $CONFIGDIR
mkdir -p $AUTHDIR/../wmcore-auth

# environment variables required to run some of the WMCore services
export REQMGR_CACHE_DIR=$STATEDIR
export WMCORE_CACHE_DIR=$STATEDIR

# overwrite host PEM files in /data/srv area by the robot certificate
# Note that the proxy file IS required and used in MSUnmerged
if [ -f /etc/robots/robotkey.pem ]; then
    sudo cp /etc/robots/robotkey.pem $AUTHDIR/dmwm-service-key.pem
    sudo cp /etc/robots/robotcert.pem $AUTHDIR/dmwm-service-cert.pem
    sudo chown $USER.$USER $AUTHDIR/dmwm-service-key.pem
    sudo chown $USER.$USER $AUTHDIR/dmwm-service-cert.pem
    sudo chmod 0400 $AUTHDIR/dmwm-service-key.pem
fi

# overwrite proxy if it is present in /etc/proxy
if [ -f /etc/proxy/proxy ]; then
    export X509_USER_PROXY=/etc/proxy/proxy
    mkdir -p /data/srv/state/$srv/proxy
    [[ -h $AUTHDIR/proxy.cert ]] && rm -rf $AUTHDIR/proxy.cert
    ln -s /etc/proxy/proxy $AUTHDIR/proxy.cert
fi

if [ -e $AUTHDIR/dmwm-service-cert.pem ] && [ -e $AUTHDIR/dmwm-service-key.pem ]; then
    export X509_USER_CERT=$AUTHDIR/dmwm-service-cert.pem
    export X509_USER_KEY=$AUTHDIR/dmwm-service-key.pem
fi

# overwrite header-auth key file with one from secrets
if [ -f /etc/hmac/hmac ]; then
    sudo cp /etc/hmac/hmac $AUTHDIR/../wmcore-auth/header-auth-key
    sudo chown $USER.$USER $AUTHDIR/../wmcore-auth/header-auth-key
    sudo chmod 0600 $AUTHDIR/../wmcore-auth/header-auth-key
fi

# use service configuration files from /etc/secrets if they are present
files=`ls /etc/secrets`
for fname in $files; do
    if [ -f /etc/secrets/$fname ]; then
        if [ -f $CONFIGDIR/$fname ]; then
            rm $CONFIGDIR/$fname
        fi
        sudo cp /etc/secrets/$fname $CONFIGDIR/$fname
        sudo chown $USER.$USER $CONFIGDIR/$fname
        if [ "$fname" == "$CONFIGFILE" ]; then
            CFGFILE=$CONFIGDIR/$CONFIGFILE
        fi
    fi
done
files=`ls /etc/secrets`
for fname in $files; do
    if [ ! -f $CONFIGDIR/$fname ]; then
        sudo cp /etc/secrets/$fname $AUTHDIR/$fname
        sudo chown $USER.$USER $AUTHDIR/$fname
    fi
done

export PYTHONPATH=$PYTHONPATH:/etc/secrets:$AUTHDIR/$fname

# backward compatible changes for RPM based deployment location of aux files
if [ -d /usr/local/data ] && [ "$USER" == "_reqmgr2" ]; then
   sudo mkdir -p /data/srv/current/apps/reqmgr2
   sudo ln -s /usr/local/data /data/srv/current/apps/reqmgr2
fi

# Edit the MSUnmerged configuration file (msConfig for the service) at runtime
# based on the set of arguments passed to the run.sh script by the service
# statrtup command defined in the .yaml file of the currently starting service
[[ -n $rseExpr ]] && sed -i -e "s/^[[:blank:]]*RSEEXPR.*/RSEEXPR = \"${rseExpr}\"/g" $CFGFILE

# start the service
wmc-httpd -r -d $STATEDIR -l "|rotatelogs $LOGDIR/$srv-%Y%m%d-`hostname -s`.log 86400" $CFGFILE

# start monitor.sh script
if [ -f /data/monitor.sh ]; then
    /data/monitor.sh
fi

# hack to keep the container running
tail -f /etc/hosts
