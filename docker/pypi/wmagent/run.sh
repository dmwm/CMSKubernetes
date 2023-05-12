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
    -f <db_flavour>   Relational Database flavour. Possible optinos are: 'mysql' or 'oracle' (Default: myslq)
    -c <central_services> Url to central services hosting central couchdb (Default: cmsweb-testbed.cern.ch)

Example: ./run.sh -n 30 -t testbed-vocms001 -c cmsweb-testbed.cern.ch -f mysql

EOF
}

usage(){
    help $1
    exit 1
}

# The container hostname must be properly fetched from the host and passed as `docker run --hostname=$hostname`
HOSTNAME=`hostname -f`
HOSTIP=`hostname -i`

# Setup defaults:
[[ $WMA_TAG == $WMCoreVersion ]] || {
    echo "WARNING: Container WMA_TAG: $WAM_TAG and actual WMCoreVersion: $WMCoreVersion mismatch."
    echo "WARNING: Assuming  WMA_TAG=$WMCoreVersion"
    WMA_TAG=$WMCoreVersion
}

TEAMNAME=testbed-${HOSTNAME%%.*}
CENTRAL_SERVICES=cmsweb-testbed.cern.ch
AGENT_NUMBER=0
FLAVOR=mysql

# Find the current WMAgent Docker image BuildId:
# NOTE: The $WMA_BUILD_ID is exported only from $WMA_USER/.bashrc but not from the Dockerfile ENV command
[[ -n $WMA_BUILD_ID ]] || WMA_BUILD_ID=$(cat $WMA_ROOT_DIR/.dockerBuildId) || { echo "ERROR: Cuold not find/set WMA_UILD_ID"; exit 1 ;}

# TODO: To fix the bellow two exports in the manage script - this will breack backwards compatibility
# NOTE: The $WMAGENTPY3_ROOT is exported only from $WMA_USER/.bashrc but not from the Dockerfile ENV command
# NOTE: The $WMAGENTPY3_VERSION is exported only from $WMA_USER/.bashrc but not from the Dockerfile ENV command

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

# Check runtime arguments:
TEAMNAME_REG="(^production$|^testbed-.*$|^dev-.*$|^relval.*$)"
[[ $TEAMNAME =~ $TEAMNAME_REG ]] || { echo "TEAMNAME: $TEAMNAME does not match requered expression: $TEAMNAME_REG"; echo "EXIT with Error 1"  ; exit 1 ;}

FLAVOR_REG="(^oracle$|^mysql$)"
[[ $FLAVOR =~ $FLAVOR_REG ]] || { echo "FLAVOR: $FLAVOR does not match requered expression: $FLAVOR_REG"; echo "EXIT with Error 1"  ; exit 1 ;}


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

source $WMA_ENV_FILE

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

_parse_wmasecrets(){
    # Auxiliary function to provide basic parsing of the WMAgent.secrets file
    # :param $1: path to WMAgent.secrets file
    local errVal=0
    local value=""
    local secretsFile=$1
    # All variables need to be fetched in lowercase through: ${var,,}
    local badValuesReg="(update-me|updateme|<update-me>|<updateme>|fix-me|fixme|<fix-me>|<fixme>|^$)"
    local varsToCheck=`awk -F\= '{print $1}' $secretsFile | grep -vE "^[[:blank:]]*#.*$"`
    for var in $varsToCheck
    do
        value=`grep -E "^[[:blank:]]*$var" $secretsFile | awk -F\= '{print $2}'`
        [[ ${value,,} =~ $badValuesReg ]] && { echo "$FUNCNAME: Bad value for: $var=$value"; let errVal+=1 ;}
    done
    return $errVal
}

_init_valid(){
    # Auxiliary function to shorten repetitive compares of */.dockerInit files to the current WMA_BUILD_TAG
    # :param $1: The path tho the .dockerInit file to be checked.
    # NOTE:      It works both ways: with and without providing the .dockerInit file at the end of the path
    local dockerInit=${1%.dockerInit}/.dockerInit
    [[ -n $dockerInit ]] && [[ -f $dockerInit ]] && [[ `cat $dockerInit` == $WMA_BUILD_ID ]]
}

deploy_to_host(){
    # This function does all the needed Docker image to Host modifications at Runtime
    # DONE: Here to execute all local config and manage/copy opertaions from the image deploy area of the container to the host
    #       * creation of all config directories if missing at the mount point
    #          * reimplement init_install_dir
    #          * reimplement init_config_dir
    #       * copy/override the manage file at the host mount point with the manage file from the image deployment area
    #       * copy/override all config files if the agent have never been initialised
    #       * create/touch a .dockerInit file containing the wMA_BUILD_ID of the current docker image
    #         * eventually the docker container Id may be considered in the future as well (the unique hash id to be used not the contaner name)
    #
    # NOTE: On every step we need to check the .dockerInit file content. There are two level of comparision we can make:
    #       * the current container Id with the already intialised one: if we want reinitailisation on every container kill/start
    #       * the current image Id with the already initialised one: if we want reinitialisation only on docker image rebuild (New WMAgent deployment).
    #       THE implementation considers the later - reinitialisation on container rebuild
    local stepMsg="Performing Docker image to Host initialisation steps"
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"

    # Check if the host has all needed components' logs and job cache areas
    # TODO: purge job cache if -p run option has been set
    echo "$FUNCNAME: Initialise install"
    _init_valid $WMA_INSTALL_DIR || {
        mkdir -p $WMA_INSTALL_DIR/{wmagent,mysql,couchdb} && echo $WMA_BUILD_ID > $WMA_INSTALL_DIR/.dockerInit
        [[ -h $WMA_INSTALL_DIR/wmagentpy3 ]] || ln -s $WMA_INSTALL_DIR/wmagent $WMA_INSTALL_DIR/wmagentpy3
    }

    # Check if the host has all config files and copy them if missing
    # NOTE: The final config/.dockerInit is to be set after full agent initialisation during `agent_upload_config`
    echo "$FUNCNAME: Initialise config"
    local serviceList="wmagent mysql couchdb rucio"
    local config_mysql=my.cnf
    local config_couchdb=local.ini
    local config_wmagent=manage
    local config_rucio=rucio.cfg
    for service in $serviceList; do
        _init_valid $WMA_CONFIG_DIR/$service && continue
        echo "$FUNCNAME: config service=$service"
        local errVal=0
        local config=config_$service && config=${!config}        # expanding to the proper config name
        if [[ $service = "wmagent" ]]
        then
            [[ -d $WMA_CONFIG_DIR/$service ]] || mkdir -p $WMA_CONFIG_DIR/$service ; let errVal+=$?
            cp -f $WMA_DEPLOY_DIR/bin/${config} $WMA_CONFIG_DIR/$service/ ; let errVal+=$?
            chmod 755 $WMA_CONFIG_DIR/$service/$config;
            [[ -h $WMA_CONFIG_DIR/wmagentpy3 ]] || ln -s $WMA_CONFIG_DIR/$service $WMA_CONFIG_DIR/wmagentpy3
        elif [[ $service = "rucio" ]]
        then
            [[ -d $WMA_CONFIG_DIR/$service/etc ]] || mkdir -p $WMA_CONFIG_DIR/$service/etc ; let errVal+=$?
            cp -f $WMA_DEPLOY_DIR/etc/${config} $WMA_CONFIG_DIR/$service/etc/ ; let errVal+=$?
        else
            [[ -d $WMA_CONFIG_DIR/$service ]] || mkdir -p $WMA_CONFIG_DIR/$service ; let errVal+=$?
            cp -f $WMA_DEPLOY_DIR/etc/${config} $WMA_CONFIG_DIR/$service/ ; let errVal+=$?
        fi
        [[ $errVal -eq 0 ]] && echo $WMA_BUILD_ID > $WMA_CONFIG_DIR/$service/.dockerInit
    done

    # Check if the host has a basic WMAgent.secrets file and copy a template if missing
    # NOTE: Here we never overwrite any existing WMAGent.secrerts file: We follow:
    #       * Check if there is any at the host, and if so, is it a blank template or a fully configured one
    #       * In case we find a legit WMAgent.secrets file we set the .dockerInit and move on
    #       * In case we need to copy a brand new template (based on the agent tape - test/prod)
    #         or a blank one found at the host we halt without updating the .dockerInit file
    #         and we ask the user to examine/update the file.
    #       (Re)Initialisation should never pass beyond that step unless properly
    #       configured WMAgent.secrets file being provided at the host.
    echo "$FUNCNAME: Initialise WMAgent.secrets"
    _init_valid $WMA_HOSTADMIN_DIR || {
        if [[ ! -f $WMA_HOSTADMIN_DIR/WMAgent.secrets ]]; then
            # NOTE: we consider production templates for relval agents and testbed templates for dev- agents
            local agentType=${TEAMNAME%%-*}
            agentType=${agentType/relval*/production}
            agentType=${agentType/dev*/testbed}
            echo "$FUNCNAME: copying $WMA_DEPLOY_DIR/etc/WMAgent.$agentType to $WMA_HOSTADMIN_DIR/WMAgent.secrets"
            cp -f $WMA_DEPLOY_DIR/etc/WMAgent.$agentType $WMA_HOSTADMIN_DIR/WMAgent.secrets
        fi
        echo "$FUNCNAME: checking $WMA_HOSTADMIN_DIR/WMAgent.secrets"
        if (_parse_wmasecrets $WMA_HOSTADMIN_DIR/WMAgent.secrets); then
            echo $WMA_BUILD_ID > $WMA_HOSTADMIN_DIR/.dockerInit
        else
            echo "ERROR: We found a blank WMAgent.secrets file template at the current host!"
            echo "ERROR: Please update it properly before reinitialising the WMagent container!"
            return $(false)
        fi
    }

    echo "Done: $stepMsg"
    echo "-------------------------------------------------------"
}

check_wmasecrets(){
    # Check if the the current WMAgent.secrets file is the same as the one from the latest agent inititialisation
    echo "$FUNCNAME: Checking for changes in the WMAgent.secrets file"
    touch $WMA_HOSTADMIN_DIR/.WMAgent.secrets.md5
    if (md5sum --quiet -c $WMA_HOSTADMIN_DIR/.WMAgent.secrets.md5); then
        echo "$FUNCNAME: No change fund."
    else
        echo "$FUNCNAME: WARNING: Wrong checksum for WMAgent.secrets file. Restarting agent initialisation."
        rm -f $WMA_HOSTADMIN_DIR/.dockerInit
        rm -f $WMA_CONFIG_DIR/.dockerInit
    fi
}

deploy_to_container() {
    # This function does all the needed Host to Docker image modifications at Runtime
    # NOTE: Here we identify the type (prod/test) and flavour (mysql/oracle) and domain (CERN/FNAL) of the agent and then:
    #       * Copy WMAgent.secrets files from host to the container - it will be needed by the manage script during initialisation and startup steps
    #       * call check certs and all other authentications
    #
    # NOTE: On every step to check the .dockerInit file contend and compare similarly to deploy_to_host
    #       but do NOT update it
    local stepMsg="Performing local Docker image initialisation steps"
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"

    # Copy the WMAgent.secrets file from the host admin area to container admin area where $manage is about to search it
    # DONE: To preserve the md5sum of the initially deployed WMAegnt.secrets file from
    #       the host, so if we find out that it has been eddited, all the reinitialisation
    #       steps to be repeated upon container restart.
    echo "$FUNCNAME: Try Copying the host WMAgent.secrets file into the container admin area"
    if _init_valid $WMA_HOSTADMIN_DIR; then
        # grep -vE "^[[:blank:]]*#.*$" $WMA_HOSTADMIN_DIR/WMAgent.secrets > $WMA_ADMIN_DIR/WMAgent.secrets
        cp -f $WMA_HOSTADMIN_DIR/WMAgent.secrets $WMA_ADMIN_DIR/
        md5sum $WMA_HOSTADMIN_DIR/WMAgent.secrets > $WMA_HOSTADMIN_DIR/.WMAgent.secrets.md5
        echo "$FUNCNAME: Done"
    else
        echo "$FUNCNAME: Not intialised WMAgent.secrets file. Skipping the current step."
        return $(false)
    fi

    # Update WMagent.secrets file:
    echo "$FUNCNAME: Updating WMAgent.secrets file with the current host's details"
    sed -i "s/MYSQL_USER=.*/MYSQL_USER=$WMA_USER/g" $WMA_ADMIN_DIR/WMAgent.secrets
    sed -i "s/COUCH_USER=.*/COUCH_USER=$WMA_USER/g" $WMA_ADMIN_DIR/WMAgent.secrets
    sed -i "s/COUCH_HOST=127\.0\.0\.1/COUCH_HOST=$HOSTIP/g" $WMA_ADMIN_DIR/WMAgent.secrets

    # Double checking the final result:
    echo "$FUNCNAME: Double checking the final WMAgent.secrets file"
    (_parse_wmasecrets $WMA_ADMIN_DIR/WMAgent.secrets) || return $(false)

    # Checking Certificates and proxy;
    echo "$FUNCNAME: Checking Certificates and Proxy"
    local certMinLifetimeHours=168
    local certMinLifetimeSec=$(($certMinLifetimeHours*60*60))
    # DONE: Here to find out if the agent is CERN or FNAL and change renew_proxy.sh respectively
    if [[ "$HOSTNAME" == *cern.ch ]]; then
        local myproxyCredName="amaltaroCERN"
    elif [[ "$HOSTNAME" == *fnal.gov ]]; then
        local myproxyCredName="amaltaroFNAL"
    else
        echo "$FUNCNAME: ERROR: Sorry, we do not recognize the network domain name of the current host: $HOSTNAME"
        return $(false)
    fi
    sed -i "s/credname=CREDNAME/credname=$myproxyCredName/g" $WMA_ADMIN_DIR/renew_proxy.sh
    chmod 755 $WMA_ADMIN_DIR/renew_proxy.sh

    # Here to check certificates and update myproxy if needed:
    if [[ -f $WMA_CERTS_DIR/servicecert.pem ]] && [[ -f $WMA_CERTS_DIR/servicekey.pem ]]; then

        echo "$FUNCNAME: Checking Certificate lifetime:"
        local now=$(date +%s)
        local certEndDate=$(openssl x509 -in $WMA_CERTS_DIR/servicecert.pem -noout -enddate)
        certEndDate=${certEndDate##*=}
        echo "$FUNCNAME: Certifficate end date: $certEndDate"
        [[ -z $certEndDate ]] && { echo "ERROR: Failed to determine certificate end date!"; return $(false) ;}

        certEndDate=$(date --date="$certEndDate" +%s)
        [[ $certEndDate -le $now ]] && { echo "ERROR: Expired certificate at $WMA_CERTS_DIR/servicecert.pem!"; return $(false) ;}
        [[ $(($certEndDate -$now)) -le $certMinLifetimeSec ]] && { echo "WARNING: The service certificate lifetime is less than certMinLifetimeHours: $certMinLifetimeHours! Please update it ASAP!" ;}

        # Renew myproxy if needed:
        echo "$FUNCNAME: Checking myproxy lifetime:"
        local myproxyEndDate=$(openssl x509 -in $WMA_CERTS_DIR/myproxy.pem -noout -enddate)
        myproxyEndDate=${myproxyEndDate##*=}
        echo "$FUNCNAME: myproxy end date: $myproxyEndDate"
        [[ -n $myproxyEndDate ]] || ($WMA_ADMIN_DIR/renew_proxy.sh) || { echo "ERROR: Failed to renew invalid myproxy"; return $(false) ;}

        myproxyEndDate=$(date --date="$myproxyEndDate" +%s)
        [[ $myproxyEndDate -gt $now ]] || ($WMA_ADMIN_DIR/renew_proxy.sh) || { echo "ERROR: Failed to renew expired myproxy"; return $(false) ;}

        # Stay safe and always change the service {cert,key} and myproxy mode here:
        sudo chmod 600 $WMA_CERTS_DIR/*
        echo "$FUNCNAME: OK"
    else
        echo "ERROR: We found no service certificate installed at $WMA_CERTS_DIR!"
        echo "ERROR: Please install proper cert and key files before restarting the WMAgent container!"
        return $(false)
    fi

    # Update flavor/type/domain global variables if needed
    # (grep -E "^[[:blank:]]*ORACLE_" $WMA_ADMIN_DIR/WMAgent.secrets > /dev/null) && CURR_FLAVOR=oracle || CURR_FLAVOR=mysql

    echo "Done: $stepMsg"
    echo "-------------------------------------------------------"
}

_check_oracle()
{
    # Auxiliary finction to check if the oracle database configured for the current agent is empty
    # NOTE: Oracle is centraly provided - we require an empty database for every account/agent
    #       otherwise we cannot guarantie this is the only agent to connect to the so configured database
    echo "$FUNCNAME: Checking whether the oracle database is clean and not used by other agents ..."
    $manage db-prompt<<"    EOF">/tmp/db_check_output
    SELECT COUNT(*) from USER_TABLES;
    EOF
    tables=`cat /tmp/db_check_output | grep -A1 '\-\-\-\-' | tail -n 1`
    rm -rf /tmp/db_check_output
    if [ "$tables" -gt 0 ]; then
        echo "ERROR: Non empty database found: $tables tables."; return $(false)
    else
        echo "OK"; return $(true)
    fi
}

_check_mysql()
{
    # Auxiliary finction to check if the the MariaDB database for the current agent is properly set
    # TODO: To be implemented in the issue related to the MariaDB setup fro wmagent
    echo "$FUNCNAME: Checking whether the mysql schema has been installed"
    true
}

check_databases() {
    # TODO: Here to check all databases - relational and CouchDB
    #       * call check_oracle or check_sql or similar
    #       * call check_couchdb
    local oracleCred=false
    local mysqlCred=false
    (grep -E "^[[:blank:]]*(ORACLE_USER)" $WMA_ADMIN_DIR/WMAgent.secrets > /dev/null) && \
        (grep -E "^[[:blank:]]*(ORACLE_PASS)" $WMA_ADMIN_DIR/WMAgent.secrets > /dev/null) && \
        (grep -E "^[[:blank:]]*(ORACLE_TNS)" $WMA_ADMIN_DIR/WMAgent.secrets > /dev/null) && \
        oracleCred=true

    (grep -E "^[[:blank:]]*(MYSQL_USER)" $WMA_ADMIN_DIR/WMAgent.secrets > /dev/null) && \
        (grep -E "^[[:blank:]]*(MYSQL_PASS)" $WMA_ADMIN_DIR/WMAgent.secrets > /dev/null) && \
        mysqlCred=true

    # Checking for relational database credentials at WMAgent.secrets file
    case $FLAVOR in
        mysql)
            $mysqlCred   || { echo "ERROR: No Mysql database credentials provided at $WMA_ADMIN_DIR/WMAgent.secrets"; return $(false) ;}
            _check_mysql || { echo "ERROR: MaridDB database unreachable or not cleaned"; return $(false) ;}
            ;;
        oracle)
            $oracleCred   || { echo "ERROR: No Oracle database credentials provided at $WMA_ADMIN_DIR/WMAgent.secrets"; return $(false) ;}
            _check_oracle || { echo "ERROR: Oracle database unreachable or not cleaned"; return $(false) ;}
        ;;
    esac
}

check_docker_init() {
    # A function to check all previously populated */.dockerInit files
    # from all previous steps and compare them with the /data/.dockerBuildId
    # if all do not match we cannot continue - we consider configuration/version
    # mismatch between the host and the container

    local DOCKER_INIT_LIST="
        $WMA_INSTALL_DIR
        $WMA_CONFIG_DIR
        $WMA_CONFIG_DIR/wmagent
        $WMA_CONFIG_DIR/mysql
        $WMA_CONFIG_DIR/couchdb
        $WMA_CONFIG_DIR/rucio
        $WMA_HOSTADMIN_DIR
        "
    local stepMsg="Performing checks for successful Docker initialisation steps..."
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"
    # touch $DOCKER_INIT_LIST
    local dockerInitId=""
    local dockerInitIdValues=""
    local idValue=""
    for initFile in $DOCKER_INIT_LIST; do
        initFile=$initFile/.dockerInit
        _init_valid $initFile && idValue=$(cat $initFile 2>&1) || idValue=$initFile
        dockerInitIdValues="$dockerInitIdValues $idValue"
    done
    dockerInitId=$(for id in $dockerInitIdValues; do echo $id; done |sort|uniq)
    echo "WMA_BUILD_ID: $WMA_BUILD_ID"
    echo "dockerInitId: $dockerInitId"
    [[ $dockerInitId == $WMA_BUILD_ID ]] && { echo "OK"; return $(true) ;} || { echo "ERROR"; return $(false) ;}

}

activate_agent() {
    local stepMsg="Performing $FUNCNAME"
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"
    _init_valid $WMA_CONFIG_DIR || {
        echo "$FUNCNAME: triggered."
        $manage activate-agent || { echo "ERROR: Failed to activate WMAgent!"; return $(false) ;}
    }
    echo "Done: $stepMsg"
    echo "-------------------------------------------------------"
}

init_agent() {
    local stepMsg="Performing $FUNCNAME"
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"
    _init_valid $WMA_CONFIG_DIR || {
        echo "$FUNCNAME: triggered."
        $manage init-agent || { echo "ERROR: Failed to initialise WMAgent databases!"; return $(false) ;}
    }
    echo "Done: $stepMsg"
    echo "-------------------------------------------------------"
}

agent_tweakconfig() {
    local stepMsg="Performing $FUNCNAME"
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"
    _init_valid $WMA_CONFIG_DIR || {
        echo "$FUNCNAME: triggered."
        [[ -f $WMA_MANAGE_DIR/config.py ]] || { echo "ERROR: Missing WMAgent config!"; return $(false) ;}

        echo "$FUNCNAME: Making agent configuration changes needed for Docker"
        # make this a docker agent
        sed -i "s+Agent.isDocker = False+Agent.isDocker = True+" $WMA_MANAGE_DIR/config.py
        # update the location of submit.sh for docker
        sed -i "s+config.JobSubmitter.submitScript.*+config.JobSubmitter.submitScript = '$WMA_CURRENT_DIR/install/wmagent/Docker/etc/submit.sh'+" $WMA_MANAGE_DIR/config.py
        # replace all tags with current
        sed -i "s+$WMA_TAG+current+" $WMA_MANAGE_DIR/config.py

        echo "$FUNCNAME: Making other agent configuration changes"
        sed -i "s+REPLACE_TEAM_NAME+$TEAMNAME+" $WMA_MANAGE_DIR/config.py
        sed -i "s+Agent.agentNumber = 0+Agent.agentNumber = $AGENT_NUMBER+" $WMA_MANAGE_DIR/config.py
        if [[ "$TEAMNAME" == relval ]]; then
            sed -i "s+config.TaskArchiver.archiveDelayHours = 24+config.TaskArchiver.archiveDelayHours = 336+" $WMA_MANAGE_DIR/config.py
        elif [[ "$TEAMNAME" == *testbed* ]] || [[ "$TEAMNAME" == *dev* ]]; then
            GLOBAL_DBS_URL=https://cmsweb-testbed.cern.ch/dbs/int/global/DBSReader
            sed -i "s+DBSInterface.globalDBSUrl = 'https://cmsweb.cern.ch/dbs/prod/global/DBSReader'+DBSInterface.globalDBSUrl = '$GLOBAL_DBS_URL'+" $WMA_MANAGE_DIR/config.py
            sed -i "s+DBSInterface.DBSUrl = 'https://cmsweb.cern.ch/dbs/prod/global/DBSReader'+DBSInterface.DBSUrl = '$GLOBAL_DBS_URL'+" $WMA_MANAGE_DIR/config.py
        fi

        local forceSiteDown=""
        [[ "$HOSTNAME" == *cern.ch ]] && forceSiteDown="'T3_US_NERSC'"

        if [[ "$HOSTNAME" == *fnal.gov ]]; then
            sed -i "s+forceSiteDown = \[\]+forceSiteDown = \[$forceSiteDown\]+" $WMA_MANAGE_DIR/config.py
        else
            sed -i "s+forceSiteDown = \[\]+forceSiteDown = \[$forceSiteDown\]+" $WMA_MANAGE_DIR/config.py
        fi
    }
    echo "Done: $stepMsg"
    echo "-------------------------------------------------------"
}

agent_resource_control() {
    local stepMsg="Performing $FUNCNAME"
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"
    _init_valid $WMA_CONFIG_DIR || {
        echo "$FUNCNAME: triggered."
        local errVal=0
        ### Populating resource-control
        echo "$FUNCNAME: Populating resource-control"
        if [[ "$TEAMNAME" == relval* || "$TEAMNAME" == *testbed* ]]; then
            echo "$FUNCNAME: Adding only T1 and T2 sites to resource-control..."
            $manage execute-agent wmagent-resource-control --add-T1s --plugin=SimpleCondorPlugin --pending-slots=50 --running-slots=50 --down ; let errVal+=$?
            $manage execute-agent wmagent-resource-control --add-T2s --plugin=SimpleCondorPlugin --pending-slots=50 --running-slots=50 --down ; let errVal+=$?
        else
            echo "$FUNCNAME: Adding ALL sites to resource-control..."
            $manage execute-agent wmagent-resource-control --add-all-sites --plugin=SimpleCondorPlugin --pending-slots=50 --running-slots=50 --down ; let errVal+=$?
        fi
        [[ $errVal -eq 0 ]] || { echo "ERROR: Failed to populate WMAgent's resource control!"; return $(false) ;}
    }
    echo "Done: $stepMsg"
    echo "-------------------------------------------------------"
}

agent_upload_config(){
    # A function to be used for uploading WMAgentConfig to AuxDB at Central CouchDB
    # NOTE: The final config/.dockerInit is to be set here after full agent initialisation.
    #       Once we have reached to the step of uploading the agent config to Cerntral CouchDB
    #       we consider all previous reintialisation and config steps as successfully complpeted.
    #       Steps to follow:
    #       * Checking if the current image WMA_BUILD_ID matches the last one successfully initialised at the host
    #       * If not, tries to upload the current config to Central CouchDB
    #       * If agent config successfully uploaded, preserve the WMA_BUILD_ID at config/.dockerInit
    #       With that, we consider the agent initialisation fully complete. The init steps will not be
    #       repeated on further container restarts unless any of the */.dockerInit files at the host is altered.
    local stepMsg="Performing $FUNCNAME"
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"

    _init_valid $WMA_CONFIG_DIR || {
        echo "$FUNCNAME: triggered."
        echo "$FUNCNAME: Tweaking central agent configuration befre uploading"
        local centralServicesUrl="https://$CENTRAL_SERVICES/reqmgr2/data/wmagentconfig"
        if [[ "$TEAMNAME" == production ]]; then
            echo "$FUNCNAME: Agent connected to the production team, setting it to drain mode"
            agentExtraConfig='{"UserDrainMode":true}'
        elif [[ "$TEAMNAME" == *testbed* ]]; then
            echo "$FUNCNAME: Testbed agent, setting MaxRetries to 0..."
            agentExtraConfig='{"MaxRetries":0}'
        elif [[ "$TEAMNAME" == *dev* ]]; then
            echo "$FUNCNAME: Dev agent, setting MaxRetries to 0..."
            agentExtraConfig='{"MaxRetries":0}'
        fi
        ### Upload WMAgentConfig to AuxDB
        echo "*** Upload WMAgentConfig to AuxDB ***"
        # TODO: Temporary stop uploading the config. To be reverted once we are ready with reconfiguring with pypi pkg env
        # $manage execute-agent wmagent-upload-config $agentExtraConfig && echo $WMA_BUILD_ID > $WMA_CONFIG_DIR/.dockerInit ;}
        true && echo $WMA_BUILD_ID > $WMA_CONFIG_DIR/.dockerInit ;}

    echo "Done: $stepMsg"
    echo "-------------------------------------------------------"
}

start_services() {
    local stepMsg="Performing $FUNCNAME"
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"
    $manage start-services
    echo "Done: $stepMsg"
    echo "-------------------------------------------------------"
}

start_agent() {
    local stepMsg="Performing $FUNCNAME"
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"
    echo "-------------------------------------------------------"
    echo "Start sleeping now ...zzz..."
    while true; do sleep 10; done
    $manage start-agent || return $(false)
    echo "Done: $stepMsg"
    echo "-------------------------------------------------------"
}

main(){
    basic_checks
    check_wmasecrets
    check_docker_init || {
        (deploy_to_host)         || { err=$?; echo "ERROR: deploy_to_host"; exit $err ;}
        (deploy_to_container)    || { err=$?; echo "ERROR: deploy_to_container"; exit $err ;}
        (activate_agent)         || { err=$?; echo "ERROR: activate_agent"; exit $err ;}
        start_services
        sleep 5
        (check_databases)        || { err=$?; echo "ERROR: check_databases"; exit $err ;}
        (init_agent)             || { err=$?; echo "ERROR: init_agent"; exit $err ;}
        sleep 5
        (agent_tweakconfig)      || { err=$?; echo "ERROR: agent_tweakconfig"; exit $err ;}
        (agent_resource_control) || { err=$?; echo "ERROR: agent_resource_control"; exit $err ;}
        (agent_upload_config)    || { err=$?; echo "ERROR: agent_upload_config"; exit $err ;}
        (check_docker_init)      || { err=$?; echo "ERROR: DockerBuild vs. HostConfiguration version missmatch"; exit $err ; }

        echo && echo "Docker container has been initialised! However you still need to:"
        echo "  1) Double check agent configuration: less current/config/wmagent/config.py"
        echo "  2) Start the agent with on of the bellow commands: "
        echo "      manage start-agent     (from inside a running wmagent container)"
        echo "      ./wmagent-docker-run & (from the host)"
        echo "Have a nice day!" && echo
        return $(true)
    }
    (deploy_to_container)        || { err=$?; echo "ERROR: deploy_to_container"; exit $err ;}
    start_services
    sleep 5
    (check_databases)            || { err=$?; echo "ERROR: check_databases"; exit $err ;}
    (start_agent)                || { err=$?; echo "ERROR: start_agent"; exit $err ;}
}

main


exit 0



# ###########################################################################################
# # NOTE: Leftovers - to be adopted/reimplemented in the GH issue dealing with CouchDB setup
# ###########################################################################################

# DATA_SIZE=`lsblk -bo SIZE,MOUNTPOINT | grep ' /data1' | sort | uniq | awk '{print $1}'`
# DATA_SIZE_GB=`lsblk -o SIZE,MOUNTPOINT | grep ' /data1' | sort | uniq | awk '{print $1}'`
# if [[ $DATA_SIZE -gt 200000000000 ]]; then  # greater than ~200GB
# echo "Partition /data1 available! Total size: $DATA_SIZE_GB"
# sleep 0.5
# while true; do
# read -p "Would you like to deploy couchdb in this /data1 partition (yes/no)? " yn
# case $yn in
# [Y/y]* ) DATA1=true; break;;
# [N/n]* ) DATA1=false; break;;
# * ) echo "Please answer yes or no.";;
# esac
# done
# else
# DATA1=false
# fi && echo

# echo -e "\n*** Applying (for couchdb1.6, etc) cert file permission ***"
# chmod 600 /data/certs/service{cert,key}.pem
# echo "Done!"

# echo "*** Checking if couchdb migration is needed ***"
# echo -e "\n[query_server_config]\nos_process_limit = 50" >> $WMA_CURRENT_DIR/config/couchdb/local.ini
# if [ "$DATA1" = true ]; then
# ./manage stop-services
# sleep 5
# if [ -d "/data1/database/" ]; then
# echo "Moving old database away... "
# mv /data1/database/ /data1/database_old/
# FINAL_MSG="5) Remove the old database when possible (/data1/database_old/)"
# fi
# rsync --remove-source-files -avr /data/srv/wmagent/current/install/couchdb/database /data1
# sed -i "s+database_dir = .*+database_dir = /data1/database+" $WMA_CURRENT_DIR/config/couchdb/local.ini
# sed -i "s+view_index_dir = .*+view_index_dir = /data1/database+" $WMA_CURRENT_DIR/config/couchdb/local.ini
# ./manage start-services
# fi
# echo "Done!" && echo
# ###########################################################################################
