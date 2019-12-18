#!/bin/sh

### This script is a hacked up deploy-wmagent.sh that has the parts that are needed
### to start an agent in a docker container

### For now these parameters are not used, but we could pass env variables to this
### script when calling docker run. Leaving the usage comments for now.

### Usage: run.sh -h
### Usage:               -w <wma_version>  WMAgent version (tag) available in the WMCore repository
### Usage:               -d <deployment_tag>   CMSWEB deployment tag used for the WMAgent deployment
### Usage:               -t <team_name>    Team name in which the agent should be connected to
### Usage:               -s <scram_arch>   The RPM architecture (defaults to slc5_amd64_gcc461)
### Usage:               -p <patches>      List of PR numbers in double quotes and space separated (e.g., "5906 5934 5922")
### Usage:               -n <agent_number> Agent number to be set when more than 1 agent connected to the same team (defaults to 0)
### Usage:               -c <central_services> Url to central services hosting central couchdb (e.g. alancc7-cloud1.cern.ch)
### Usage:
### Usage: run.sh -w <wma_version> -d <deployment_tag> -t <team_name> [-s <scram_arch>] [-n <agent_number>] [-c <central_services_url>]
### Usage: Example: sh run.sh -w 1.2.6.patch1 -d HG1909e -t production -n 30
### Usage: Example: sh run.sh -w 1.2.4.patch3 -d HG1908a -t testbed-vocms001 -p "9315 9364 9367" -c cmsweb-testbed.cern.ch
### Usage:

set -x

WMA_TAG=1.2.8
DEPLOY_TAG=HG1909e
TEAMNAME=testbed-erik
CENTRAL_SERVICES=esg-dmwm-dev1.cern.ch
AG_NUM=0
FLAVOR=mysql
PATCHES="9453"

IAM=`whoami`
HOSTNAME=`hostname -f`
MY_IP=`host $HOSTNAME | awk '{print $4}'`

BASE_DIR=/data/srv
DEPLOY_DIR=$BASE_DIR/wmagent
CURRENT_DIR=$BASE_DIR/wmagent/current
CONFIG_DIR=$CURRENT_DIR/config
INSTALL_DIR=$CURRENT_DIR/install
MANAGE_DIR=$BASE_DIR/wmagent/current/config/wmagent/
ADMIN_DIR=/data/admin/wmagent
ENV_FILE=/data/admin/wmagent/env.sh
CERTS_DIR=/data/certs/

### Usage function: print the usage of the script
usage()
{
  perl -ne '/^### Usage:/ && do { s/^### ?//; print }' < $0
  exit 1
}

### Help function: print help for this script
help()
{
  perl -ne '/^###/ && do { s/^### ?//; print }' < $0
  exit 0
}

### Runs some basic checks before actually starting the deployment procedure
basic_checks()
{
  echo -n "Checking whether this node has the very basic setup for the agent deployment..."
  set -e
  if [ ! -d $ADMIN_DIR ]; then
    echo -e "  FAILED!\n Could not find $ADMIN_DIR."
    exit 5
  elif [ ! -f $ADMIN_DIR/WMAgent.secrets ]; then
    echo -e "  FAILED!\n Could not find $ADMIN_DIR/WMAgent.secrets."
    exit 6
  elif [ ! -f $ENV_FILE ]; then
    echo -e "\n  Could not find $ENV_FILE, but I'm downloading it now."
    wget -nv https://raw.githubusercontent.com/dmwm/WMCore/master/deploy/env.sh -O $ENV_FILE
  fi
  echo -n "Checking the config and install directories are set up"  
  if [ ! -f $CONFIG_DIR/.dockerinit ]; then
    init_config_dir
  fi
  if [ ! -f $INSTALL_DIR/.dockerinit ]; then
    init_install_dir
  fi
  if [ ! -d $CERTS_DIR ]; then
    echo -e "  FAILED!\n Could not find $CERTS_DIR"
    exit 7
  else
    check_certs
  fi
  
  set +e
}

check_certs()
{
  echo -ne "\nChecking whether the certificates and proxy are in place ..."
  if [ ! -f $CERTS_DIR/myproxy.pem ] || [ ! -f $CERTS_DIR/servicecert.pem ] || [ ! -f $CERTS_DIR/servicekey.pem ]; then
    echo -e "\n  ... nope, trying to copy them from another node, you might be prompted for the cmst1 password."
    set -e
    if [[ "$IAM" == cmst1 ]]; then
      scp cmst1@vocms0250:/data/certs/* /data/certs/
    else
      scp cmsdataops@cmsgwms-submit3:/data/certs/* /data/certs/
    fi
    set +e
    chmod 600 $CERTS_DIR/*
  else
    chmod 600 $CERTS_DIR/*
  fi
  echo -e "  OK!\n"
}

check_oracle()
{
  echo "Checking whether the oracle database is clean and not used by other agents ..."

  tmpdir=`mktemp -d`
  cd $tmpdir

  wget -nv https://raw.githubusercontent.com/dmwm/deployment/master/wmagent/manage -O manage
  chmod +x manage
  echo -e "SELECT COUNT(*) from USER_TABLES;" > check_db_status.sql
  ### FIXME: new nodes don't have sqlplus ... what to do now?
  ./manage db-prompt < check_db_status.sql > db_check_output
  tables=`cat db_check_output | grep -A1 '\-\-\-\-' | tail -n 1`
  if [ "$tables" -gt 0 ]; then
    echo "  FAILED!\n This database is likely being used by another agent! Found $tables tables. Quitting!"
    exit 9
  else
    echo -e "  OK!\n"
  fi
  cd -
  rm -rf $tmpdir
}

init_install_dir() {

  # create the install directory during run, when install dir is bind mounted
  echo "Making the required install directories"
  mkdir -p $INSTALL_DIR/{wmagent,reqmgr,workqueue,mysql,couchdb}
  mkdir -p $INSTALL_DIR/wmagent/Docker/{WMRuntime,etc}
  # grab two scripts that need to be available on the bind mounted install directory
  # TODO: grab these in a more sane way
  cp -fv /data/srv/wmagent/current/sw/slc7_amd64_gcc630/cms/wmagent/*/etc/submit.sh $INSTALL_DIR/wmagent/Docker/etc
  cp -fv /data/srv/wmagent/current/sw/slc7_amd64_gcc630/cms/wmagent/*/lib/python2.7/site-packages/WMCore/WMRuntime/Unpacker.py $INSTALL_DIR/wmagent/Docker/WMRuntime

  # keep track of bind mounted install dir initialization
  touch $INSTALL_DIR/.dockerinit
}

init_config_dir() {

  # create the base configuration during run, when config dir is bind mounted
  echo "Making the base configuration directories"
  local root=/data/srv/wmagent
  # note the "v" here is "very" important
  cfgversion=v$WMA_TAG
  mkdir -p $root/$cfgversion/config/wmagent

  cp -fv /data/srv/deployment-$DEPLOY_TAG/wmagent/* $root/$cfgversion/config/wmagent

  mkdir -p $root/$cfgversion/config/{reqmgr,workqueue,mysql,couchdb,rucio/etc}

  local couchdb_ini=$root/$cfgversion/config/wmagent/local.ini
  perl -p -i -e "s{deploy_project_root}{$root/$cfgversion/install}g" $couchdb_ini
  cp -f $couchdb_ini $root/$cfgversion/config/couchdb/

  local mysql_config=$root/$cfgversion/config/wmagent/my.cnf
  cp -f $mysql_config $root/$cfgversion/config/mysql/

  local rucio_config=$root/$cfgversion/config/wmagent/rucio.cfg
  cp -f $rucio_config $root/$cfgversion/config/rucio/etc/
  
  # keep track of bind mounted config dir initialization
  touch $CONFIG_DIR/.dockerinit 
}

# not parsing command line arguments for now
#for arg; do
#  case $arg in
#    -h) help ;;
#    -w) WMA_TAG=$2; shift; shift ;;
#    -d) DEPLOY_TAG=$2; shift; shift ;;
#    -t) TEAMNAME=$2; shift; shift ;;
#    -p) PATCHES=$2; shift; shift ;;
#    -n) AG_NUM=$2; shift; shift ;;
#    -c) CENTRAL_SERVICES=$2; shift; shift ;;
#    -*) usage ;;
#  esac
#done

if [[ -z $WMA_TAG ]] || [[ -z $DEPLOY_TAG ]] || [[ -z $TEAMNAME ]]; then
  usage
  exit 2
fi

basic_checks

source $ENV_FILE;

### Are we using Oracle or MySQL
MATCH_ORACLE_USER=`cat $WMAGENT_SECRETS_LOCATION | grep ORACLE_USER | sed s/ORACLE_USER=//`
if [ "x$MATCH_ORACLE_USER" != "x" ]; then
FLAVOR=oracle
check_oracle
fi


if [[ "$HOSTNAME" == *cern.ch ]]; then
MYPROXY_CREDNAME="amaltaroCERN"
FORCEDOWN="'T3_US_NERSC'"
elif [[ "$HOSTNAME" == *fnal.gov ]]; then
MYPROXY_CREDNAME="amaltaroFNAL"
FORCEDOWN=""
else
echo "Sorry, I don't know this network domain name"
exit 3
fi

DATA_SIZE=`lsblk -bo SIZE,MOUNTPOINT | grep ' /data1' | sort | uniq | awk '{print $1}'`
DATA_SIZE_GB=`lsblk -o SIZE,MOUNTPOINT | grep ' /data1' | sort | uniq | awk '{print $1}'`
if [[ $DATA_SIZE -gt 200000000000 ]]; then  # greater than ~200GB
echo "Partition /data1 available! Total size: $DATA_SIZE_GB"
sleep 0.5
while true; do
read -p "Would you like to deploy couchdb in this /data1 partition (yes/no)? " yn
case $yn in
[Y/y]* ) DATA1=true; break;;
[N/n]* ) DATA1=false; break;;
* ) echo "Please answer yes or no.";;
esac
done
else
DATA1=false
fi && echo

echo -e "\n*** Applying (for couchdb1.6, etc) cert file permission ***"
chmod 600 /data/certs/service{cert,key}.pem
echo "Done!"

echo -e "\n*** Removing the current crontab ***"
/usr/bin/crontab -r;
echo "Done!"

#cd $BASE_DIR/deployment-$DEPLOY_TAG
# XXX: update the PR number below, if needed :-)
#echo -e "\n*** Applying database schema patches ***"
#cd $CURRENT_DIR
#  wget -nv https://github.com/dmwm/WMCore/pull/8315.patch -O - | patch -d apps/wmagent/bin -p 2
#cd -
#echo "Done!" && echo

# By default, it will only work for official WMCore patches in the general path
echo -e "\n*** Applying agent patches ***"
if [ "x$PATCHES" != "x" ]; then
  cd $CURRENT_DIR
  for pr in $PATCHES; do
    wget -nv https://github.com/dmwm/WMCore/pull/$pr.patch -O - | patch -d apps/wmagent/lib/python2*/site-packages/ -p 3
  done
cd -
fi
echo "Done!" && echo

echo -e "\n*** Activating the agent ***"
cd $MANAGE_DIR
./manage activate-agent
echo "Done!" && echo

echo "*** Starting services ***"
cd $MANAGE_DIR
./manage start-services
echo "Done!" && echo
sleep 5

echo "*** Initializing the agent ***"
./manage init-agent
echo "Done!" && echo
sleep 5

echo "*** Checking if couchdb migration is needed ***"
echo -e "\n[query_server_config]\nos_process_limit = 50" >> $CURRENT_DIR/config/couchdb/local.ini
if [ "$DATA1" = true ]; then
./manage stop-services
sleep 5
if [ -d "/data1/database/" ]; then
echo "Moving old database away... "
mv /data1/database/ /data1/database_old/
FINAL_MSG="5) Remove the old database when possible (/data1/database_old/)"
fi
rsync --remove-source-files -avr /data/srv/wmagent/current/install/couchdb/database /data1
sed -i "s+database_dir = .*+database_dir = /data1/database+" $CURRENT_DIR/config/couchdb/local.ini
sed -i "s+view_index_dir = .*+view_index_dir = /data1/database+" $CURRENT_DIR/config/couchdb/local.ini
./manage start-services
fi
echo "Done!" && echo

###
# tweak configuration
### 
echo "*** Tweaking configuration ***"
echo "*** Making agent configuration changes needed for Docker ***"
# make this a docker agent
sed -i "s+Agent.isDocker = False+Agent.isDocker = True+" $MANAGE_DIR/config.py
# update the location of submit.sh for docker
sed -i "s+config.JobSubmitter.submitScript.*+config.JobSubmitter.submitScript = '$CURRENT_DIR/install/wmagent/Docker/etc/submit.sh'+" $MANAGE_DIR/config.py
# replace all tags with current
sed -i "s+v$WMA_TAG+current+" $MANAGE_DIR/config.py

echo "*** Making other agent configuration changes ***"
sed -i "s+REPLACE_TEAM_NAME+$TEAMNAME+" $MANAGE_DIR/config.py
sed -i "s+Agent.agentNumber = 0+Agent.agentNumber = $AG_NUM+" $MANAGE_DIR/config.py
if [[ "$TEAMNAME" == relval ]]; then
sed -i "s+config.TaskArchiver.archiveDelayHours = 24+config.TaskArchiver.archiveDelayHours = 336+" $MANAGE_DIR/config.py
elif [[ "$TEAMNAME" == *testbed* ]] || [[ "$TEAMNAME" == *dev* ]]; then
GLOBAL_DBS_URL=https://cmsweb-testbed.cern.ch/dbs/int/global/DBSReader
sed -i "s+DBSInterface.globalDBSUrl = 'https://cmsweb.cern.ch/dbs/prod/global/DBSReader'+DBSInterface.globalDBSUrl = '$GLOBAL_DBS_URL'+" $MANAGE_DIR/config.py
sed -i "s+DBSInterface.DBSUrl = 'https://cmsweb.cern.ch/dbs/prod/global/DBSReader'+DBSInterface.DBSUrl = '$GLOBAL_DBS_URL'+" $MANAGE_DIR/config.py
fi

if [[ "$HOSTNAME" == *fnal.gov ]]; then
sed -i "s+forceSiteDown = \[\]+forceSiteDown = \[$FORCEDOWN\]+" $MANAGE_DIR/config.py
else
sed -i "s+forceSiteDown = \[\]+forceSiteDown = \[$FORCEDOWN\]+" $MANAGE_DIR/config.py
fi
echo "Done!" && echo

### Populating resource-control
echo "*** Populating resource-control ***"
cd $MANAGE_DIR
if [[ "$TEAMNAME" == relval* || "$TEAMNAME" == *testbed* ]]; then
echo "Adding only T1 and T2 sites to resource-control..."
./manage execute-agent wmagent-resource-control --add-T1s --plugin=SimpleCondorPlugin --pending-slots=50 --running-slots=50 --down
./manage execute-agent wmagent-resource-control --add-T2s --plugin=SimpleCondorPlugin --pending-slots=50 --running-slots=50 --down
else
echo "Adding ALL sites to resource-control..."
./manage execute-agent wmagent-resource-control --add-all-sites --plugin=SimpleCondorPlugin --pending-slots=50 --running-slots=50 --down
fi
echo "Done!" && echo

echo "*** Tweaking central agent configuration ***"
CENTRAL_SERVICES="https://$CENTRAL_SERVICES/reqmgr2/data/wmagentconfig"
if [[ "$TEAMNAME" == production ]]; then
echo "Agent connected to the production team, setting it to drain mode"
agentExtraConfig='{"UserDrainMode":true}'
elif [[ "$TEAMNAME" == *testbed* ]]; then
echo "Testbed agent, setting MaxRetries to 0..."
agentExtraConfig='{"MaxRetries":0}'
elif [[ "$TEAMNAME" == *devvm* ]]; then
echo "Dev agent, setting MaxRetries to 0..."
agentExtraConfig='{"MaxRetries":0}'
fi
echo "Done!" && echo

### Upload WMAgentConfig to AuxDB
echo "*** Upload WMAgentConfig to AuxDB ***"
cd $MANAGE_DIR
./manage execute-agent wmagent-upload-config $agentExtraConfig
echo "Done!" && echo

### Populating cronjob with utilitarian scripts
echo "*** Creating cronjobs for them ***"
if [[ "$TEAMNAME" == *testbed* || "$TEAMNAME" == *dev* ]]; then
( crontab -l 2>/dev/null | grep -Fv ntpdate
echo "55 */12 * * * (export X509_USER_CERT=/data/certs/servicecert.pem; export X509_USER_KEY=/data/certs/servicekey.pem; myproxy-get-delegation -v -l amaltaro -t 168 -s 'myproxy.cern.ch' -k $MYPROXY_CREDNAME -n -o /data/certs/mynewproxy.pem && voms-proxy-init -rfc -voms cms:/cms/Role=production -valid 168:00 -noregen -cert /data/certs/mynewproxy.pem -key /data/certs/mynewproxy.pem -out /data/certs/myproxy.pem)"
) | crontab -
else
( crontab -l 2>/dev/null | grep -Fv ntpdate
echo "55 */12 * * * (export X509_USER_CERT=/data/certs/servicecert.pem; export X509_USER_KEY=/data/certs/servicekey.pem; myproxy-get-delegation -v -l amaltaro -t 168 -s 'myproxy.cern.ch' -k $MYPROXY_CREDNAME -n -o /data/certs/mynewproxy.pem && voms-proxy-init -rfc -voms cms:/cms/Role=production -valid 168:00 -noregen -cert /data/certs/mynewproxy.pem -key /data/certs/mynewproxy.pem -out /data/certs/myproxy.pem)"
echo "58 */12 * * * python /data/admin/wmagent/checkProxy.py --proxy /data/certs/myproxy.pem --time 120 --send-mail True --mail alan.malta@cern.ch"
echo "#workaround for the ErrorHandler silence issue"
echo "*/15 * * * *  source /data/admin/wmagent/restartComponent.sh > /dev/null"
) | crontab -
fi
echo "Done!" && echo

set +x

echo && echo "Docker container is running! However you still need to:"
echo "  1) Source the new WMA env: source /data/admin/wmagent/env.sh"
echo "  2) Double check agent configuration: less config/wmagent/config.py"
echo "  3) Start the agent with: \$manage start-agent"
echo "  $FINAL_MSG"
echo "Have a nice day!" && echo

exit 0
