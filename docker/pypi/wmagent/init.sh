#!/bin/bash

### This script is used to start the WMAgent services deployed from Pypi
### * All agent related configuration parameters are read from WMAgent.secrets file
###   at runtime and are used to (re)generate the agent configuration files.
### * All service credentials and schedd caches are accessed via host mount points
### * The agent's hostname && HTCondor configuration are taken from the host

WMCoreVersion=$(python -c "from WMCore import __version__ as WMCoreVersion; print(WMCoreVersion)")
pythonLib=$(python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")

# Load common definitions and environment:
source $WMA_DEPLOY_DIR/bin/manage-common.sh
source $WMA_ENV_FILE

# The container hostname must be properly fetched from the host and passed as `docker run --hostname=$hostname`
HOSTNAME=`hostname -f`
HOSTIP=`hostname -i`

# Setup defaults:
[[ $WMA_TAG == $WMCoreVersion ]] || {
    echo "WARNING: Container WMA_TAG: $WMA_TAG and actual WMCoreVersion: $WMCoreVersion mismatch."
    echo "WARNING: Assuming  WMA_TAG=$WMCoreVersion"
    WMA_TAG=$WMCoreVersion
}

[[ -z $WMA_USER ]] && export WMA_USER=$(id -un)

TEAMNAME=testbed-${HOSTNAME%%.*}
AGENT_NUMBER=0
AGENT_FLAVOR=mysql

# Initial load of the WMAgent.secrets file. Here variables like TEAMNAME, AGENT_NUMBER and AGENT_FLAVOR
# are to be defined for the first time or otherwise their default values will be used
[[ -f $WMA_SECRETS_FILE ]] && _load_wmasecrets

# Find the current WMAgent BuildId:
# NOTE: The $WMA_BUILD_ID is exported from $WMA_ENV_FILE but not from the Dockerfile ENV command
[[ -n $WMA_BUILD_ID ]] || WMA_BUILD_ID=$(cat $WMA_ROOT_DIR/.wmaBuildId) || { echo "ERROR: Could not find/set WMA_BUILD_ID"; exit 1 ;}

# Check runtime arguments:
TEAMNAME_REG="(^production$|^testbed-.*$|^dev-.*$|^relval.*$|^Tier0.*$)"
[[ $TEAMNAME =~ $TEAMNAME_REG ]] || { echo "TEAMNAME: $TEAMNAME does not match required expression: $TEAMNAME_REG"; echo "EXIT with Error 1"  ; exit 1 ;}

FLAVOR_REG="(^oracle$|^mysql$)"
[[ $AGENT_FLAVOR =~ $FLAVOR_REG ]] || { echo "FLAVOR: $AGENT_FLAVOR does not match required expression: $FLAVOR_REG"; echo "EXIT with Error 1"  ; exit 1 ;}

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
echo " - WMAgent Relational DB type : $AGENT_FLAVOR"
echo " - Python  Version            : $(python --version)"
echo " - Python  Module path        : $pythonLib"
echo "======================================================="
echo

_check_mounts() {
    # An auxiliary function to check if a given mountpoint is among the actually
    # bind mounted volumes from the host
    # :param $1: The mountpoint to be checked
    # :return: true/false

    # Avoid checking for mounts when not running from docker
    _is_venv && return $(true)
    local mounts=$(mount |grep -E "(/data|/etc/condor|/tmp)" |awk '{print $3}')
    local mountPoint=$(realpath $1 2>/dev/null)
    [[ " $mounts " =~  ^.*[[:space:]]+$mountPoint[[:space:]]+.*$  ]] && return $(true) || return $(false)
}

basic_checks() {

    local stepMsg="Performing $FUNCNAME"
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"
    echo

    local errMsg=""
    errMsg="$FUNCNAME: ERROR: Could not find $WMA_ENV_FILE."
    [[ -e $WMA_ENV_FILE ]] || { err=$?; echo -e "$errMsg"; exit $err ;}

    errMsg="$FUNCNAME: ERROR: Could not find $WMA_ADMIN_DIR mount point"
    [[ -d $WMA_ADMIN_DIR ]] && _check_mounts $WMA_ADMIN_DIR || { err=$?; echo -e "$errMsg"; exit $err ;}

    errMsg="$FUNCNAME: ERROR: Could not find $WMA_CONFIG_DIR mount point"
    [[ -d $WMA_CONFIG_DIR ]] && _check_mounts $WMA_CONFIG_DIR || { err=$?; echo -e "$errMsg"; exit $err ;}

    errMsg="$FUNCNAME: ERROR: Could not find $WMA_INSTALL_DIR mount point"
    [[ -d $WMA_INSTALL_DIR ]] && _check_mounts $WMA_INSTALL_DIR || { err=$?; echo -e "$errMsg"; exit $err ;}

    errMsg="$FUNCNAME: ERROR: Could not find $WMA_CERTS_DIR mount point"
    [[ -d $WMA_CERTS_DIR ]] && _check_mounts $WMA_CERTS_DIR || { err=$?; echo -e "$errMsg"; exit $err ;}
    echo "Done: $stepMsg"
    echo "-------------------------------------------------------"
    echo
}

_copy_runtime() {
    # Auxiliary function to copy all scripts needed at runtime from the WMAgent image to the host

    # Avoid copying the run time scripts if not running from inside a Docker container
    _is_venv && {
        echo $WMA_BUILD_ID > $wmaInitRuntime
        return
    }

    # checking if $WMA_DEPLOY_DIR is root path for $pythonLib:
    if [[ $pythonLib =~ ^$WMA_DEPLOY_DIR ]]; then
        mkdir -p $WMA_INSTALL_DIR/Docker/
        echo "$FUNCNAME: Copying content from: $pythonLib/WMCore/WMRuntime to: $WMA_INSTALL_DIR/Docker/"
        cp -ra $pythonLib/WMCore/WMRuntime $WMA_INSTALL_DIR/Docker/
        echo "$FUNCNAME: Copying content from: $WMA_DEPLOY_DIR/etc/ to: $WMA_CONFIG_DIR/"
        cp -ra $WMA_DEPLOY_DIR/etc/ $WMA_CONFIG_DIR/
        echo $WMA_BUILD_ID > $wmaInitRuntime
    else
        echo "$FUNCNAME: ERROR: \$WMA_DEPLOY_DIR: $WMA_DEPLOY_DIR is not a root path for \$pythonLib: $pythonLib"
        echo "$FUNCNAME: ERROR: We cannot find the correct WMCore/WMRuntime source to copy at the current host!"
        return $(false)
    fi
}

deploy_to_host(){
    # This function does all Host modifications needed at Runtime

    local stepMsg="Performing Host initialization steps"
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"

    # TODO: This is to be removed once we decide to run it only from the deploy area
    #       The only place left where the manage script is called directly from
    #       $WMA_CONFIG_DIR is from $WMA_DEPLOY_DIR/bin/clean-oracle
    echo "$FUNCNAME: Linking the proper manage file from Config Area"

    if [[ -h $WMA_CONFIG_DIR/manage ]] || [[ -f $WMA_CONFIG_DIR/manage ]]; then
        rm -f $WMA_CONFIG_DIR/manage
    fi
    ln -s $WMA_MANAGE_DIR/manage $WMA_CONFIG_DIR/manage

    echo "$FUNCNAME: Copy the Runtime scripts"
    _init_valid $wmaInitRuntime || _copy_runtime

    # Check if the host has a basic WMAgent.secrets file and copy a template if missing
    # NOTE: Here we never overwrite any existing WMAGent.secrets file: We follow:
    #       * Check if there is any at the host, and if so, is it a blank template or a fully configured one
    #       * In case we find a legit WMAgent.secrets file we set the .initAdmin and move on
    #       * In case we need to copy a brand new template (based on the agent type - test/prod )
    #         or a blank one found at the host we halt without updating the .initAdmin file
    #         and we ask the user to examine/update the file.
    #       (Re)Initialization should never pass beyond that step unless properly
    #       configured WMAgent.secrets file being provided at the host.
    echo "$FUNCNAME: Initialize && Validate && Load WMAgent.secrets"
    _init_valid $wmaInitAdmin || {
        if [[ ! -f $WMA_SECRETS_FILE ]]; then
            # NOTE: we consider production templates for relval agents and testbed templates for dev- agents
            local agentType=${TEAMNAME%%-*}
            agentType=${agentType/relval*/production}
            agentType=${agentType/dev*/testbed}
            echo "$FUNCNAME: copying $WMA_DEPLOY_DIR/etc/WMAgent.$agentType to $WMA_SECRETS_FILE"
            cp -f $WMA_DEPLOY_DIR/deploy/WMAgent.$agentType $WMA_SECRETS_FILE
            # Update WMagent.secrets file:
            echo "$FUNCNAME: Updating WMAgent.secrets file with the current host's details"
            sed -i "s/MDB_USER=.*/MDB_USER=$WMA_USER/g" $WMA_SECRETS_FILE
            sed -i "s/COUCH_USER=.*/COUCH_USER=$WMA_USER/g" $WMA_SECRETS_FILE
            sed -i "s/COUCH_HOST=127\.0\.0\.1/COUCH_HOST=$HOSTIP/g" $WMA_SECRETS_FILE
        fi
        echo "$FUNCNAME: checking $WMA_SECRETS_FILE"
        if (_parse_wmasecrets $WMA_SECRETS_FILE); then
            md5sum $WMA_SECRETS_FILE > $WMA_ADMIN_DIR/.WMAgent.secrets.md5
            echo $WMA_BUILD_ID > $wmaInitAdmin
            # reload to finally validated $WMA_SECRETS_FILE:
            _load_wmasecrets
        else
            echo "$FUNCNAME: ERROR: We found a blank WMAgent.secrets file template at the current host!"
            echo "$FUNCNAME: ERROR: Please update it properly before reinitialising the WMagent container!"
            return $(false)
        fi
    }

    echo "$FUNCNAME: Initialise Rucio config"
    _init_valid $wmaInitRucio || {
        [[ -d $WMA_CONFIG_DIR/etc ]] || mkdir -p $WMA_CONFIG_DIR/etc
        cp -f $WMA_DEPLOY_DIR/etc/rucio.cfg $WMA_CONFIG_DIR/etc/
        # update the rucio.cfg file with the proper parameters from the secrets file
        local rucio_host=$RUCIO_HOST
        local rucio_auth=$RUCIO_AUTH
        if [[ "$TEAMNAME" == *testbed* ]] || [[ "$TEAMNAME" == *dev* ]]; then
            rucio_host=http://cms-rucio.cern.ch
            rucio_auth=https://cms-rucio-auth.cern.ch
        fi
        sed -i "s+RUCIO_HOST_OVERWRITE+$rucio_host+" $WMA_CONFIG_DIR/etc/rucio.cfg
        sed -i "s+RUCIO_AUTH_OVERWRITE+$rucio_auth+" $WMA_CONFIG_DIR/etc/rucio.cfg
        echo $WMA_BUILD_ID > $wmaInitRucio
    }

    echo "$FUNCNAME: Checking Certificates and Proxy"
    _renew_proxy

    echo "Done: $stepMsg"
    echo "-------------------------------------------------------"
}

check_wmasecrets(){
    # Check if the the current WMAgent.secrets file is the same as the one from the latest agent initialization
    echo "$FUNCNAME: Checking for changes in the WMAgent.secrets file"
    touch $WMA_ADMIN_DIR/.WMAgent.secrets.md5
    if (md5sum --quiet -c $WMA_ADMIN_DIR/.WMAgent.secrets.md5); then
        echo "$FUNCNAME: No change found."
    else
        echo "$FUNCNAME: WARNING: Wrong checksum for WMAgent.secrets file. Restarting agent configuration."
        rm -f $wmaInitAdmin
        rm -f $wmaInitConfig
        rm -f $wmaInitRucio
        echo "$FUNCNAME: WARNING: NOT cleaning SQL and Couch databases. If you are aware the change in WMAgent.secrets file"
        echo "$FUNCNAME: WARNING: is to affect them, please consider executing 'manage clean-agent' and restart the agent."
        # rm -f $wmaInitCouchDB
        # rm -f $wmaInitSqlDB

    fi
}

_check_oracle() {
    # Auxiliary function to check if the oracle database configured for the current agent is empty
    # NOTE: Oracle is centrally provided - we require an empty database for every account/agent
    #       otherwise we cannot guarantee this is the only agent to connect to the so configured database
    # NOTE: Here to check if the wmagent database exists and if so to check if it was done from
    #       a container with the current $WMA_BUILD_ID
    echo "$FUNCNAME: Checking whether the Oracle server is reachable ..."
    _status_of_oracle || return $(false)

    echo "$FUNCNAME: Checking whether the Oracle database is clean and not used by other agents ..."
    # NOTE: if _init_valid $wmaInitSqlDB:
    #         we search for a fully deployed schema and check for match between schema_id and WMA_BUILD_ID
    #       if not _init_valid $wmaInitSqlDB
    #         we require and empty wmagent database and halt if not empty
    local cleanMessage="You may consider dropping it with 'manage clean-oracle'"
    if _init_valid $wmaInitSqlDB ; then
        # _sql_schema_valid || { echo "$FUNCNAME: ERROR: Invalid database schema. $cleanMessage"; return $(false) ;}
        _sql_dbid_valid   || { echo "$FUNCNAME: ERROR: A database initialized by an agent with different Build ID. $cleanMessage' "; return $(false) ;}
    else
        _sql_db_isclean   || { echo "$FUNCNAME: ERROR: Nonempty database. $cleanMessage"; return $(false) ;}
    fi
}

_check_mysql() {
    # Auxiliary function to check if the MariaDB database for the current agent is properly set
    # NOTE: Here to check if the wmagent database exists and if so to check if it was done from
    #       a container with the current $WMA_BUILD_ID
    echo "$FUNCNAME: Checking whether the MySQL server is reachable..."
    _status_of_mysql || return $(false)

    echo "$FUNCNAME: Checking whether the MySQL schema has been installed"
    # NOTE: if _init_valid $wmaInitSqlDB:
    #         we search for a fully deployed schema and check for match between schema_id and WMA_BUILD_ID
    #       if not _init_valid $wmaInitSqlDB
    #         we require empty or missing wmagent database and halt if not the case
    local cleanMessage="You may consider dropping it with 'manage clean-mysql'"
    if _init_valid $wmaInitSqlDB ; then
        _sql_schema_valid || { echo "$FUNCNAME: ERROR: Invalid database schema. $cleanMessage"; return $(false) ;}
        _sql_dbid_valid   || { echo "$FUNCNAME: ERROR: A database initialized by an agent with different Build ID. $cleanMessage' "; return $(false) ;}
    else
        _sql_db_isclean   || { echo "$FUNCNAME: ERROR: Nonempty database. $cleanMessage"; return $(false) ;}
    fi
}

_check_couch() {
    # Auxiliary function to check if the CouchDB database for the current agent is properly set
    echo "$FUNCNAME: Checking whether the CouchDB database is reachable..."
    _status_of_couch || return $(false)

    # echo "$FUNCNAME: Additional checks for CouchDB:"
    # NOTE: To implement any additional check to the CouchDB similar to the relational databases
}

check_databases() {
    # TODO: Here to check all databases - relational and CouchDB
    #       * call check_oracle or check_sql or similar
    #       * call check_couchdb
    local oracleCred=false
    local mysqlCred=false
    [[ -n $ORACLE_USER ]] && [[ -n $ORACLE_PASS ]] && [[ -n $ORACLE_TNS ]] && \
        oracleCred=true

    [[ -n $MDB_USER ]] && [[ -n $MDB_PASS ]] && \
        mysqlCred=true

    # Checking the relational databases:
    case $AGENT_FLAVOR in
        mysql)
            $mysqlCred   || { echo "$FUNCNAME: ERROR: No Mysql database credentials provided at $WMA_SECRETS_FILE"; return $(false) ;}
            _check_mysql || return
            ;;
        oracle)
            $oracleCred   || { echo "$FUNCNAME: ERROR: No Oracle database credentials provided at $WMA_SECRETS_FILE"; return $(false) ;}
            _check_oracle || return
        ;;
    esac

    # Checking CouchDB:
    _check_couch
}

set_cronjob() {
    stepMsg="Populating cronjob with utilitarian scripts for user: $WMA_USER"
    echo "-----------------------------------------------------------------------"
    echo "Start: $stepMsg"
    local errVal=0

    # Populating proxy related cronjobs
    crontab -u $WMA_USER - <<EOF
55 */12 * * * $WMA_MANAGE_DIR/manage renew-proxy
58 */12 * * * python $WMA_DEPLOY_DIR/deploy/checkProxy.py --proxy /data/certs/myproxy.pem --time 120 --send-mail True --mail alan.malta@cern.ch
*/15 * * * *  source $WMA_DEPLOY_DIR/deploy/restartComponent.sh > /dev/null
EOF
    let errVal+=$?

    # Populating CouchDB related cronjobs
    wmagent-couchapp-init
    let errVal+=$?

    [[ $errVal -eq 0 ]] || {
        echo "$FUNCNAME: ERROR: Failed to populate WMAgent's cron jobs for user: $WMA_USER"
        return $errVal
    }
    echo "Done: $stepMsg!" && echo
    echo "-----------------------------------------------------------------------"
}

check_wmagent_init() {
    # A function to check all previously populated */.init<step> files
    # from all previous steps and compare them with the /data/.wmaBuildId
    # if all do not match we cannot continue - we consider configuration/version
    # mismatch between the host and the container

    # NOTE: On every step we need to check the .init<step> file content. We always compare
    #       the current $WMA_BUILD_ID with the one previously initialized at the host.
    #       The WMA_BUILD_ID is generated during the execution of `install.sh`
    #       at build time (for docker images) or deploy time for virtual env
    #       There are few levels of comparison we can make:
    #       1. If we want to trigger re-initialization on any WMAgent image rebuild,
    #          then the $WMA_BUILD_ID should contain a sha256sum of a random variable
    #       2. If we want to trigger re-initialization only on new WMAgent tag builds,
    #          then the $WMA_BUILD_ID should contain a sha256sum of whole $WMA_TAG
    #       3. If we want to trigger re-initialization only on release change (not on
    #          patch version or release candidate change), then we should split
    #          $WMA_TAG in parts: major, minor and patch(release candidate) part and the
    #          $WMA_BUILD_ID should contain a sha256sum only of the release = major + minor
    #          parts excluding the patch version (release candidate) part, e.g.:
    #          WMA_TAG=2.3.3.1;
    #          WMA_VER[release]=2.3.3
    #          WMA_VER[major]=2.3
    #          WMA_VER[minor]=3
    #          WMA_VER[patch]=1
    #       The current implementation considers option 3 - trigger full initialization only on WMAgent release change

    local initFilesList="
        $wmaInitAdmin
        $wmaInitActive
        $wmaInitAgent
        $wmaInitConfig
        $wmaInitRuntime
        $wmaInitUpload
        $wmaInitResourceControl
        $wmaInitResourceOpp
        $wmaInitCouchDB
        $wmaInitSqlDB
        $wmaInitRucio
        $wmaInitUsing
        "
    local stepMsg="Performing checks for successful WMAgent initialisation steps..."
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"
    local wmaInitId=""
    local wmaInitIdValues=""
    local idValue=""
    for initFile in $initFilesList; do
        _init_valid $initFile && idValue=$(cat $initFile 2>&1) || idValue=$initFile
        wmaInitIdValues="$wmaInitIdValues $idValue"
    done
    wmaInitId=$(for id in $wmaInitIdValues; do echo $id; done |sort|uniq)
    echo "WMA_BUILD_ID: $WMA_BUILD_ID"
    echo "wmaInitId: $wmaInitId"
    [[ $wmaInitId == $WMA_BUILD_ID ]] && { echo "OK"; return $(true) ;} || { echo "WARNING: wmaInitId vs. wmaBuildId mismatch"; return $(false) ;}
}

activate_agent() {
    local stepMsg="Performing $FUNCNAME"
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"
    _init_valid $wmaInitActive || {
        echo "$FUNCNAME: triggered."
        manage activate-agent || { echo "ERROR: Failed to activate WMAgent!"; return $(false) ;}
        echo $WMA_BUILD_ID > $wmaInitActive
    }
    echo "Done: $stepMsg"
    echo "-------------------------------------------------------"
}

init_agent() {
    local stepMsg="Performing $FUNCNAME"
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"

    local wmaSchemaDump=$WMA_CONFIG_DIR/.wmaSchemaDump.sql
    if _init_valid $wmaInitAgent && \
       _init_valid $wmaInitSqlDB && \
       _init_valid $wmaInitCouchDB
    then
        echo "$FUNCNAME: The agent has been properly initialized already."
    else
        echo "$FUNCNAME: triggered."
        manage init-agent || { echo "ERROR: Failed to initialise WMAgent databases!"; return $(false) ;}

        echo $WMA_BUILD_ID > $wmaInitAgent

        # NOTE: Here already the agent and the databases are initialized. Now we need to dump the schema
        #       and mark the sql database with the current WMA_BUILD_ID for later validation on start up
        _sql_write_agentid && _sql_dumpSchema || return

        # Create the .init*DB files
        echo $WMA_BUILD_ID > $wmaInitSqlDB
        echo $WMA_BUILD_ID > $wmaInitCouchDB
    fi
    echo "Done: $stepMsg"
    echo "-------------------------------------------------------"
}

agent_tweakconfig() {
    local stepMsg="Performing $FUNCNAME"
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"
    _init_valid $wmaInitConfig || {
        echo "$FUNCNAME: triggered."
        [[ -f $WMA_CONFIG_DIR/config.py ]] || { echo "ERROR: Missing WMAgent config!"; return $(false) ;}

        # NOTE: We are not about to change the submit script and runtime sources
        #       if we are  not running from inside a Docker container
        _is_docker && {
            echo "$FUNCNAME: Making agent configuration changes needed for Docker"
            # make this a docker agent
            sed -i "s+Agent.isDocker = False+Agent.isDocker = True+" $WMA_CONFIG_DIR/config.py
            # update the location of submit.sh for docker
            sed -i "s+config.JobSubmitter.submitScript.*+config.JobSubmitter.submitScript = '$WMA_CONFIG_DIR/etc/submit_py3.sh'+" $WMA_CONFIG_DIR/config.py
            # replace all tags with current
            sed -i "s+$WMA_TAG+current+" $WMA_CONFIG_DIR/config.py
        }

        echo "$FUNCNAME: Making other agent configuration changes"
        sed -i "s+REPLACE_TEAM_NAME+$TEAMNAME+" $WMA_CONFIG_DIR/config.py
        sed -i "s+Agent.agentNumber = 0+Agent.agentNumber = $AGENT_NUMBER+" $WMA_CONFIG_DIR/config.py
        if [[ "$TEAMNAME" == relval ]]; then
            sed -i "s+config.TaskArchiver.archiveDelayHours = 24+config.TaskArchiver.archiveDelayHours = 336+" $WMA_CONFIG_DIR/config.py
        elif [[ "$TEAMNAME" == *testbed* ]] || [[ "$TEAMNAME" == *dev* ]]; then
            GLOBAL_DBS_URL=https://cmsweb-testbed.cern.ch/dbs/int/global/DBSReader
            sed -i "s+DBSInterface.globalDBSUrl = 'https://cmsweb.cern.ch/dbs/prod/global/DBSReader'+DBSInterface.globalDBSUrl = '$GLOBAL_DBS_URL'+" $WMA_CONFIG_DIR/config.py
            sed -i "s+DBSInterface.DBSUrl = 'https://cmsweb.cern.ch/dbs/prod/global/DBSReader'+DBSInterface.DBSUrl = '$GLOBAL_DBS_URL'+" $WMA_CONFIG_DIR/config.py
            rucio_host=http://cms-rucio.cern.ch
            rucio_auth=https://cms-rucio-auth.cern.ch
            sed -i "s+WorkQueueManager.rucioUrl = .*+WorkQueueManager.rucioUrl = '$rucio_host'+" $WMA_CONFIG_DIR/config.py
            sed -i "s+WorkQueueManager.rucioAuthUrl = .*+WorkQueueManager.rucioAuthUrl = '$rucio_auth'+" $WMA_CONFIG_DIR/config.py
        fi

        local forceSiteDown=""
        [[ "$HOSTNAME" == *cern.ch ]] && forceSiteDown="'T3_US_NERSC'"

        if [[ "$HOSTNAME" == *fnal.gov ]]; then
            sed -i "s+forceSiteDown = \[\]+forceSiteDown = \[$forceSiteDown\]+" $WMA_CONFIG_DIR/config.py
        else
            sed -i "s+forceSiteDown = \[\]+forceSiteDown = \[$forceSiteDown\]+" $WMA_CONFIG_DIR/config.py
        fi
        echo $WMA_BUILD_ID > $wmaInitConfig
    }
    echo "Done: $stepMsg"
    echo "-------------------------------------------------------"
}

agent_resource_control() {
    local stepMsg="Performing $FUNCNAME"
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"
    if _init_valid $wmaInitResourceControl && \
       _init_valid $wmaInitSqlDB
    then
        echo "$FUNCNAME: Agent Resource control has been populated already."
    else
        echo "$FUNCNAME: triggered."
        local errVal=0
        ### Populating resource-control
        echo "$FUNCNAME: Populating resource-control"
        if [[ "$TEAMNAME" == relval* || "$TEAMNAME" == *testbed* ]]; then
            echo "$FUNCNAME: Adding only T1 and T2 sites to resource-control..."
            manage execute-agent wmagent-resource-control --add-T1s --plugin=SimpleCondorPlugin --pending-slots=50 --running-slots=50 --down ; let errVal+=$?
            manage execute-agent wmagent-resource-control --add-T2s --plugin=SimpleCondorPlugin --pending-slots=50 --running-slots=50 --down ; let errVal+=$?
        elif [[ "$TEAMNAME" == Tier0* ]]; then
            echo "$FUNCNAME: Tier0 agent not populating resource control for this agent"
        else
            echo "$FUNCNAME: Adding ALL sites to resource-control..."
            manage execute-agent wmagent-resource-control --add-all-sites --plugin=SimpleCondorPlugin --pending-slots=50 --running-slots=50 --down ; let errVal+=$?
        fi
        [[ $errVal -eq 0 ]] || { echo "ERROR: Failed to populate WMAgent's resource control!"; return $(false) ;}
        echo $WMA_BUILD_ID > $wmaInitResourceControl
    fi
    echo "Done: $stepMsg"
    echo "-------------------------------------------------------"
}

agent_resource_opp() {
    ## In this function, the list of available opportunistic resources is added to the resource control
    ## This is done fetching the env variables starting with RESOURCE_
    ## that are associative arrays defined in WMAgent.secrets with the following schema:
    ## RESOURCE_OPP<number>=([name]=<name of the site> [run]=<total number of available running slots> [pend]=<total number of available pending slots> [state]=<status of the site>)
    local stepMsg="Performing $FUNCNAME"
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"
    if _init_valid $wmaInitResourceOpp && \
       _init_valid $wmaInitSqlDB
    then
        echo "$FUNCNAME: Agent Opportunistic Resource control has been populated already."
    else
        echo "$FUNCNAME: triggered."
        local errVal=0
        ## Populating opportunistic resource-control
        echo "$FUNCNAME: Populating opportunistic resource-control"
        ## Loop over the env variables starting with RESOURCE_*
        for resRecord in ${!RESOURCE_*}
        do
            ## Parsing of the information stored in RESOURCE_* env variable, according to the schema reported above
            eval `declare -p $resRecord | sed -e "s/$resRecord/res/g"`
            if [[ ${res[name]} =~ .*_US_.* ]] && [[ $HOSTNAME =~ .*cern\.ch ]]; then
                echo "I am based at CERN, so I cannot use US opportunistic resources, moving to the next site"
                continue
            else
                manage execute-agent wmagent-resource-control --plugin=SimpleCondorPlugin --opportunistic --pending-slots=${res[pend]} --running-slots=${res[run]} --add-one-site=${res[name]} ; let errVal+=$?
            fi
        done
        [[ $errVal -eq 0 ]] || { echo "ERROR: Failed to populate WMAgent's opportunistic resource control!"; return $errVal ;}
        echo $WMA_BUILD_ID > $wmaInitResourceOpp
    fi

    echo "Done: $stepMsg"
    echo "-------------------------------------------------------"
}



agent_upload_config(){
    # A function to be used for uploading WMAgentConfig to AuxDB at Central CouchDB
    # NOTE: The final config/.initUsing is to be set in the main() function after full agent initialization.
    #       Once we have reached to the step of uploading the agent config to Cerntral CouchDB
    #       we consider all previous re-initialization and config steps as successfully completed.
    #       Steps to follow:
    #       * Checking if the current image WMA_BUILD_ID matches the last one successfully initialized at the host
    #       * If not, tries to upload the current config to Central CouchDB
    #       * If agent config successfully uploaded, preserve the WMA_BUILD_ID at config/.initUpload
    #       With that, we consider the agent initialization fully complete. The init steps will not be
    #       repeated on further container restarts unless any of the */.init<step> files at the host is altered.
    local stepMsg="Performing $FUNCNAME"
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"

    _init_valid $wmaInitUpload || {
        echo "$FUNCNAME: triggered."
        echo "$FUNCNAME: Tweaking central agent configuration befre uploading"
        if [[ "$TEAMNAME" == production ]]; then
            echo "$FUNCNAME: Agent connected to the production team, setting it to drain mode"
            agentExtraConfig='{"UserDrainMode":true}'
        elif [[ "$TEAMNAME" == Tier0* ]]; then
            echo "$FUNCNAME: Tier0 agent not uploading configuration"
            echo $WMA_BUILD_ID > $wmaInitUpload
            return
        elif [[ "$TEAMNAME" == *testbed* ]]; then
            echo "$FUNCNAME: Testbed agent, setting MaxRetries to 0..."
            agentExtraConfig='{"MaxRetries":0}'
        elif [[ "$TEAMNAME" == *dev* ]]; then
            echo "$FUNCNAME: Dev agent, setting MaxRetries to 0..."
            agentExtraConfig='{"MaxRetries":0}'
        fi
        ### Upload WMAgentConfig to AuxDB
        echo "*** Upload WMAgentConfig to AuxDB ***"
        manage execute-agent wmagent-upload-config $agentExtraConfig && echo $WMA_BUILD_ID > $wmaInitUpload
    }
    echo "Done: $stepMsg"
    echo "-------------------------------------------------------"
}

start_agent() {
    local stepMsg="Performing $FUNCNAME"
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"
    echo "-------------------------------------------------------"
    manage stop-agent
    manage start-agent
    echo "Done: $stepMsg"
    echo "-------------------------------------------------------"
}

main(){
    basic_checks
    check_wmasecrets
    check_wmagent_init || {
        (deploy_to_host)         || { err=$?; echo "ERROR: deploy_to_host"; exit $err ;}
        (check_databases)        || { err=$?; echo "ERROR: check_databases"; exit $err ;}
        (activate_agent)         || { err=$?; echo "ERROR: activate_agent"; exit $err ;}
        (init_agent)             || { err=$?; echo "ERROR: init_agent"; exit $err ;}
        (agent_tweakconfig)      || { err=$?; echo "ERROR: agent_tweakconfig"; exit $err ;}
        (agent_resource_control) || { err=$?; echo "ERROR: agent_resource_control"; exit $err ;}
        (agent_resource_opp)     || { err=$?; echo "ERROR: agent_resource_opp"; exit $err ;}
        (agent_upload_config)    || { err=$?; echo "ERROR: agent_upload_config"; exit $err ;}
        echo $WMA_BUILD_ID > $wmaInitUsing
        (check_wmagent_init)     || { err=$?; echo "ERROR: Unresolved wmaInitId vs. wmaBuildId mismatch"; exit $err ; }
        echo && echo "Docker container has been initialised! However you still need to:"
        echo "  1) Double check agent configuration: less /data/[dockerMount]/srv/wmagent/current/config/config.py"
        echo "  2) Start the agent by either of the methods bellow:"
        echo "     a) From inside the already running container"
        echo "          * Access the running WMAgent container:"
        echo "            docker exec -it wmagent bash"
        echo "          * Use the regular manage script inside the container:"
        echo "            manage start-agent"
        echo
        echo "     b) From the host - by restarting the whole container"
        echo "          * Kill the currently running container:"
        echo "            docker kill wmagent"
        echo "          * Start a fresh instance of wmagent:"
        echo "            ./wmagent-docker-run.sh -t <WMA_TAG> && docker logs -f wmagent"
        echo
        echo "     c) If you are deploying inside a virtual environment"
        echo "          * Activate the environment:"
        echo "            cd <Deployment_dir> && . bin/activate"
        echo "          * Use the regular manage script inside the virtual environment:"
        echo "            manage start-agent"
        echo
        echo "Have a nice day!" && echo
        return $(true)
    }
    (set_cronjob)                || { err=$?; echo "ERROR: set_cronjob"; exit $err ;}
    (check_databases)            || { err=$?; echo "ERROR: check_databases"; exit $err ;}
    (_renew_proxy)               || { err=$?; echo "ERROR: _renew_proxy"; exit $err ;}
    (start_agent)                || { err=$?; echo "ERROR: start_agent"; exit $err ;}
}

main

exit 0
