#!/bin/bash

### This script is used to start the WMAgent services inside a Docker container
### * All agent related configuration parameters are fetched as named arguments
###   at runtime and used to (re)generate the agent configuration files.
### * All service credentials and schedd caches are accessed via host mount points
### * The agent's hostname && HTCondor configuration are taken from the host

WMCoreVersion=$(python -c "from WMCore import __version__ as WMCoreVersion; print(WMCoreVersion)")
pythonLib=$(python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")

help(){
    echo -e $1
    cat <<EOF

WMCoreVersion: v$WMCoreVersion

The initial run.sh script for the wmagent container. It is used to:
 * Check if all needed system mount points are in place
 * Check if all needed system services (i.e. MariaDB and CouchDB) are up and running
 * Check and populate the agent's resource-control data based on the hostname on which
   the container is about to be running
 * Create or reuse an agent configuration file based on the hostname on which
   the container is about to be running and the startup parameters sent to the script
 * Start the agent in the docker container


Usage: run.sh [-t <team_name>] [-n <agent_number>] [-c <central_services_url>] [-f <db_flavour>]

              -t <team_name>    Team name in which the agent should be connected to
              -n <agent_number> Agent number to be set when more than 1 agent connected to the same team (Default: 0)
              -f <db_flavour>   Relational Database flavour. Possible optinos are: `mysql` or `oracle` (Default: myslq)
              -c <central_services> Url to central services hosting central couchdb (Default: cmsweb-testbed.cern.ch)

Example: ./run.sh -w 2.2.0.2 -n 30 -t testbed-vocms001 -c cmsweb-testbed.cern.ch

EOF
}

usage(){
    help $1
    exit 1
}

# Setup defaults:
[[ $WMA_TAG == $WMCoreVersion ]] || {
    echo "WARNING: Container WMA_TAG: $WAM_TAG and actual WMCoreVersion: $WMCoreVersion mismatch."
    echo "WARNING: Assuming  WMA_TAG=$WMCoreVersion"
    WMA_TAG=$WMCoreVersion
}

TEAMNAME=testbed-vocms0192
CENTRAL_SERVICES=cmsweb-testbed.cern.ch
AGENT_NUMBER=0
FLAVOR=mysql

# Find the current WMAgent Docker image BuildId:
# NOTE: The $WMA_BUILD_ID is exported only from $WMA_USER/.bashrc but not from the Dockerfile ENV command
[[ -n $WMA_BUILD_ID ]] || WMA_BUILD_ID=$(cat $WMA_ROOT_DIR/.dockerBuildId) || { echo "ERROR: Cuold not find/set WMA_UILD_ID"; exit 1 ;}


### Argument parsing:
# export OPTIND=1
while getopts ":t:n:c:f:h" opt; do
    case ${opt} in
        t) TEAMNAME=$OPTARG ;;
        n) AGENT_NUMBER=$OPTARG ;;
        c) CENTRAL_SERVICES=$OPTARG ;;
        f) FLAVOR=$OPTARG ;;
        h) help; exit $? ;;
        \? )
            msg="Invalid Option: -$OPTARG"
            usage "$msg" ;;
        : )
            msg="Invalid Option: -$OPTARG requires an argument"
            usage "$msg" ;;
    esac
done


# The container hostname must be properly fetch from the host and passed as `docker run --hostname=$hostname`
HOSTNAME=`hostname -f`

echo
echo "======================================================="
echo "Starting WMAgent with the following initialisation data:"
echo "-------------------------------------------------------"
echo " - WMAgent Version            : $WMA_TAG"
echo " - WMAgent User               : $WMA_USER"
echo " - WMAgent Root path          : $WMA_ROOT_DIR"
echo " - WMAgent Host               : $HOSTNAME"
echo " - WMAgent TeamName           : $TEAMNAME"
echo " - WMAgent Number             : $AGENT_NUMBER"
echo " - WMAgent CentralServices    : $CENTRAL_SERVICES"
echo " - WMAgent Relational DB type : $FLAVOR"
echo " - Python  Verson             : $(python --version)"
echo " - Python  Module path        : $pythonLib"
echo "======================================================="
echo

_check_mounts() {
    # An auxiliay function to check if a given mountpoint is among the actually
    # bind mounted volumes from the host
    # :param $1: The mountpoint to be checked
    # :return: true/false
    local mounts=$(mount |grep -E "(/data|/etc/condor|/tmp)" |awk '{print $3}')
    local mountPoint=$(realpath $1 2>/dev/null)
    [[ " $mounts " =~  ^.*[[:space:]]+$mountPoint[[:space:]]+.*$  ]] && return $(true) || return $(false)
}

basic_checks() {

    local stepMsg="Performing basic setup checks..."
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"
    echo

    local errMsg=""
    errMsg="ERROR: Could not find $WMA_ENV_FILE."
    [[ -e $WMA_ENV_FILE ]] || { err=$?; echo -e "$errMsg"; exit $err ;}

    errMsg="ERROR: Could not find $WMA_ADMIN_DIR."
    [[ -d $WMA_ADMIN_DIR ]] || { err=$?; echo -e "$errMsg"; exit $err ;}

    errMsg="ERROR: Could not find $WMA_HOSTADMIN_DIR mount point"
    [[ -d $WMA_HOSTADMIN_DIR ]] && _check_mounts $WMA_HOSTADMIN_DIR || { err=$?; echo -e "$errMsg"; exit $err ;}

    errMsg="ERROR: Could not find $WMA_CONFIG_DIR mount point"
    [[ -d $WMA_CONFIG_DIR ]] && _check_mounts $WMA_CONFIG_DIR || { err=$?; echo -e "$errMsg"; exit $err ;}

    errMsg="ERROR: Could not find $WMA_INSTALL_DIR mount point"
    [[ -d $WMA_INSTALL_DIR ]] && _check_mounts $WMA_INSTALL_DIR || { err=$?; echo -e "$errMsg"; exit $err ;}

    errMsg="ERROR: Could not find $WMA_CERTS_DIR mount point"
    [[ -d $WMA_CERTS_DIR ]] && _check_mounts $WMA_CERTS_DIR || { err=$?; echo -e "$errMsg"; exit $err ;}
    echo "Done: $stepMsg"
    echo "-------------------------------------------------------"
    echo
}


deploy_to_container() {
# This function does all the needed Host to Docker image modifications at Runtime
# TODO: Here we should identify the type (prod/test) and flavour(mysql/oracle) of the agent and then:
#       * Merge the WMAgent secrets files from host and templates
#       * call check certs and all other authentications
#
# NOTE: On every step to check the .dockerInit file contend and compare
#       * the current container Id with the already intialised one: if we want reinitailsation on every container kill/start
#       * the current image Id with the already initialised one: if we want reinitialisation only on image refresh (New WMAgent deployment).
    local stepMsg="Performing local Docker image initialisation steps"
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"
    true
    echo "Done: $stepMsg"
    echo "-------------------------------------------------------"
}

deploy_to_host(){
# This function does all the needed Docker image to Host modifications at Runtime
# TODO: Here to execute all local config and manage copy opertaions from image deploy area to container and host
#       * creation of all config directories if missing at the mount point
#          * call init_install_dir
#          * call init_config_dir
#       * override the manage at the host  mount  point with file from the image deployment area
#       * exit if previous step fails
#       * copy/override all config files if agent have never been initialised
#       * run manage so that the agent gets initialised if never have been before.
#       * create/touch a .dockerInit file containing the current container Id and imageId
#         (the unique hash id to be used not the contaner name)
#
# NOTE: On every step to check the .dockerInit file contend and compare
#       * the current container Id with the already intialised one: if we want reinitailsation on every container kill/start
#       * the current image Id with the already initialised one: if we want reinitialisation only on image refresh (New WMAgent deployment).
    local stepMsg="Performing Docker image to Host initialisation steps"
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"

    # Check if the host has all needed components' logs and job cache areas
    # TODO: purge job cache if -p run option has been set
    [[ `cat $WMA_INSTALL_DIR/.dockerInit` == $WMA_BUILD_ID ]] || {
        mkdir -p $WMA_INSTALL_DIR/{wmagent,mysql,couchdb} && echo $WMA_BUILD_ID > $WMA_INSTALL_DIR/.dockerInit
        # local componentList="wmagent mysql couchdb"
        # local errVal=0
        # for component in $componentList; do
        #     [[ -d $WMA_INSTALL_DIR/$component ]] || mkdir -p $WMA_INSTALL_DIR/$component || let errVal+=1
        # done
        # [[ $errVal -eq 0 ]] && echo $WMA_BUILD_ID > $WMA_INSTALL_DIR/.dockerInit
    }

    # Check if the host has all config files and copy them if missing
    [[ `cat $WMA_CONFIG_DIR/.dockerInit` == $WMA_BUILD_ID ]] || {
        true && echo $WMA_BUILD_ID > $WMA_CONFIG_DIR/.dockerInit
    }

    # Check if the host has a basic WMAgent.secrets file and copy a template if missing
    [[ `cat $WMA_HOSTADMIN_DIR/.dockerInit` == $WMA_BUILD_ID ]] || {
        true  && echo $WMA_BUILD_ID > $WMA_HOSTADMIN_DIR/.dockerInit
    }

    echo "Done: $stepMsg"
    echo "-------------------------------------------------------"
}

check_databases() {
# TODO: Here to check all databases - relational and CouchDB
#       * call check_oracle or check_sql or similar
#       * call check_couchdb
    true
}

DOCKER_INIT_LIST="$WMA_INSTALL_DIR/.dockerInit $WMA_CONFIG_DIR/.dockerInit $WMA_HOSTADMIN_DIR/.dockerInit"
check_docker_init() {
    # A function to check all previously populated */.dockerInit files
    # from all previous steps and compare them with the /data/.dockerBuildId
    # if all do not match we cannot continue - we consider configuration/version
    # mismatch between the host and the container

    local stepMsg="Performing checks for successful Docker initialisation steps..."
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"
    local dockerInitId=""
    local dockerInitIdValues=""
    for initFile in $DOCKER_INIT_LIST; do
        dockerInitIdValues="$dockerInitIdValues $(cat $initFile 2>&1)"
    done
    dockerInitId=$(for id in $dockerInitIdValues; do echo $id; done |sort|uniq)
    echo "WMA_BUILD_ID: $WMA_BUILD_ID"
    echo "dockerInitId: $dockerInitId"
    [[ $dockerInitId == $WMA_BUILD_ID ]] && { echo "OK"; return $(true) ;} || { echo "ERROR"; return $(false) ;}

}

# agent_activate() {
#}

# services_start() {
#}

# agent_init() {
#}

# agent_tweakconfig() {
#

# agent_resource_control() {
#}

# agent_upload_config(){
#}

# set_crontabs() {
#}


main(){
    basic_checks
    check_docker_init || {
        deploy_to_host
        check_docker_init || { err=$?; echo -e "ERROR: DockerBuild - HostConfiguration version missmatch"; exit $err ; }
    }
    deploy_to_container
    check_databases
}

main

echo "-------------------------------------------------------"
echo "Start sleeping now ...zzz..."
while true; do sleep 10; done
echo "-------------------------------------------------------"

# set -x

### Runs some basic checks before actually starting the deployment procedure

check_certs()
{
  echo -ne "\nChecking whether the certificates and proxy are in place ..."
  if [ ! -f $WMA_CERTS_DIR/myproxy.pem ] || [ ! -f $WMA_CERTS_DIR/servicecert.pem ] || [ ! -f $WMA_CERTS_DIR/servicekey.pem ]; then
    echo -e "\n  ... nope, trying to copy them from another node, you might be prompted for the cmst1 password."
    set -e
    if [[ "$IAM" == cmst1 ]]; then
      scp cmst1@vocms0250:/data/certs/* /data/certs/
    else
      scp cmsdataops@cmsgwms-submit3:/data/certs/* /data/certs/
    fi
    set +e
    chmod 600 $WMA_CERTS_DIR/*
  else
    chmod 600 $WMA_CERTS_DIR/*
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
  mkdir -p $WMA_INSTALL_DIR/{wmagent,reqmgr,workqueue,mysql,couchdb}
  mkdir -p $WMA_INSTALL_DIR/wmagent/Docker/{WMRuntime,etc}
  # grab two scripts that need to be available on the bind mounted install directory
  # TODO: grab these in a more sane way
  cp -fv /data/srv/wmagent/current/sw/slc7_amd64_gcc630/cms/wmagent/*/etc/submit.sh $WMA_INSTALL_DIR/wmagent/Docker/etc
  cp -fv /data/srv/wmagent/current/sw/slc7_amd64_gcc630/cms/wmagent/*/lib/python2.7/site-packages/WMCore/WMRuntime/Unpacker.py $WMA_INSTALL_DIR/wmagent/Docker/WMRuntime

  # keep track of bind mounted install dir initialization
  touch $WMA_INSTALL_DIR/.dockerinit
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
  touch $WMA_CONFIG_DIR/.dockerinit
}

if [[ -z $WMA_TAG ]] || [[ -z $DEPLOY_TAG ]] || [[ -z $TEAMNAME ]]; then
  usage
  exit 2
fi

basic_checks

source $WMA_ENV_FILE;

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

#cd $WMA_BASE_DIR/deployment-$DEPLOY_TAG
# XXX: update the PR number below, if needed :-)
#echo -e "\n*** Applying database schema patches ***"
#cd $WMA_CURRENT_DIR
#  wget -nv https://github.com/dmwm/WMCore/pull/8315.patch -O - | patch -d apps/wmagent/bin -p 2
#cd -
#echo "Done!" && echo

# # By default, it will only work for official WMCore patches in the general path
# echo -e "\n*** Applying agent patches ***"
# if [ "x$PATCHES" != "x" ]; then
#   cd $WMA_CURRENT_DIR
#   for pr in $PATCHES; do
#     wget -nv https://github.com/dmwm/WMCore/pull/$pr.patch -O - | patch -d apps/wmagent/lib/python2*/site-packages/ -p 3
#   done
# cd -
# fi
# echo "Done!" && echo

echo -e "\n*** Activating the agent ***"
cd $WMA_MANAGE_DIR
./manage activate-agent
echo "Done!" && echo

echo "*** Starting services ***"
cd $WMA_MANAGE_DIR
./manage start-services
echo "Done!" && echo
sleep 5

echo "*** Initializing the agent ***"
./manage init-agent
echo "Done!" && echo
sleep 5

echo "*** Checking if couchdb migration is needed ***"
echo -e "\n[query_server_config]\nos_process_limit = 50" >> $WMA_CURRENT_DIR/config/couchdb/local.ini
if [ "$DATA1" = true ]; then
./manage stop-services
sleep 5
if [ -d "/data1/database/" ]; then
echo "Moving old database away... "
mv /data1/database/ /data1/database_old/
FINAL_MSG="5) Remove the old database when possible (/data1/database_old/)"
fi
rsync --remove-source-files -avr /data/srv/wmagent/current/install/couchdb/database /data1
sed -i "s+database_dir = .*+database_dir = /data1/database+" $WMA_CURRENT_DIR/config/couchdb/local.ini
sed -i "s+view_index_dir = .*+view_index_dir = /data1/database+" $WMA_CURRENT_DIR/config/couchdb/local.ini
./manage start-services
fi
echo "Done!" && echo

###
# tweak configuration
### 
echo "*** Tweaking configuration ***"
echo "*** Making agent configuration changes needed for Docker ***"
# make this a docker agent
sed -i "s+Agent.isDocker = False+Agent.isDocker = True+" $WMA_MANAGE_DIR/config.py
# update the location of submit.sh for docker
sed -i "s+config.JobSubmitter.submitScript.*+config.JobSubmitter.submitScript = '$WMA_CURRENT_DIR/install/wmagent/Docker/etc/submit.sh'+" $WMA_MANAGE_DIR/config.py
# replace all tags with current
sed -i "s+v$WMA_TAG+current+" $WMA_MANAGE_DIR/config.py

echo "*** Making other agent configuration changes ***"
sed -i "s+REPLACE_TEAM_NAME+$TEAMNAME+" $WMA_MANAGE_DIR/config.py
sed -i "s+Agent.agentNumber = 0+Agent.agentNumber = $AG_NUM+" $WMA_MANAGE_DIR/config.py
if [[ "$TEAMNAME" == relval ]]; then
sed -i "s+config.TaskArchiver.archiveDelayHours = 24+config.TaskArchiver.archiveDelayHours = 336+" $WMA_MANAGE_DIR/config.py
elif [[ "$TEAMNAME" == *testbed* ]] || [[ "$TEAMNAME" == *dev* ]]; then
GLOBAL_DBS_URL=https://cmsweb-testbed.cern.ch/dbs/int/global/DBSReader
sed -i "s+DBSInterface.globalDBSUrl = 'https://cmsweb.cern.ch/dbs/prod/global/DBSReader'+DBSInterface.globalDBSUrl = '$GLOBAL_DBS_URL'+" $WMA_MANAGE_DIR/config.py
sed -i "s+DBSInterface.DBSUrl = 'https://cmsweb.cern.ch/dbs/prod/global/DBSReader'+DBSInterface.DBSUrl = '$GLOBAL_DBS_URL'+" $WMA_MANAGE_DIR/config.py
fi

if [[ "$HOSTNAME" == *fnal.gov ]]; then
sed -i "s+forceSiteDown = \[\]+forceSiteDown = \[$FORCEDOWN\]+" $WMA_MANAGE_DIR/config.py
else
sed -i "s+forceSiteDown = \[\]+forceSiteDown = \[$FORCEDOWN\]+" $WMA_MANAGE_DIR/config.py
fi
echo "Done!" && echo

### Populating resource-control
echo "*** Populating resource-control ***"
cd $WMA_MANAGE_DIR
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
cd $WMA_MANAGE_DIR
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