#!/bin/bash

### This script is used to start the WMAgent services inside a Docker container
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
    echo "WARNING: Container WMA_TAG: $WAM_TAG and actual WMCoreVersion: $WMCoreVersion mismatch."
    echo "WARNING: Assuming  WMA_TAG=$WMCoreVersion"
    WMA_TAG=$WMCoreVersion
}

TEAMNAME=testbed-${HOSTNAME%%.*}
AGENT_NUMBER=0
AGENT_FLAVOR=mysql

# Initial load of the WMAgent.secrets file. Here variables like TEAMNAME, AGENT_NUMBER and AGENT_FLAVOR
# are to be defined for the first time or otherwise their default values will be used
[[ -f $WMA_SECRETS_FILE ]] && _load_wmasecrets

# Find the current WMAgent Docker image BuildId:
# NOTE: The $WMA_BUILD_ID is exported only from $WMA_USER/.bashrc but not from the Dockerfile ENV command
[[ -n $WMA_BUILD_ID ]] || WMA_BUILD_ID=$(cat $WMA_ROOT_DIR/.dockerBuildId) || { echo "ERROR: Cuold not find/set WMA_UILD_ID"; exit 1 ;}

# Check runtime arguments:
TEAMNAME_REG="(^production$|^testbed-.*$|^dev-.*$|^relval.*$)"
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

deploy_to_host(){
    # This function does all the needed Docker image to Host modifications at Runtime
    # DONE: Here to execute all local config and manage/copy opertaions from the image deploy area of the container to the host
    #       * creation of all config directories if missing at the mount point
    #          * reimplement init_install_dir
    #          * reimplement init_config_dir
    #       * copy/override the manage file at the host mount point with the manage file from the image deployment area
    #       * copy/override all config files if the agent have never been initialised
    #       * create/touch a .dockerInit file containing the WMA_BUILD_ID of the current docker image
    #         * eventually the docker container Id may be considered in the future as well (the unique hash id to be used not the contaner name)
    #
    # NOTE: On every step we need to check the .dockerInit file content. There are two level of comparision we can make:
    #       * the current container Id with the already intialised one: if we want reinitailisation on every container kill/start
    #       * the current image Id with the already initialised one: if we want reinitialisation only on docker image rebuild (New WMAgent deployment).
    #       THE implementation considers the later - reinitialisation on container rebuild
    local stepMsg="Performing Docker image to Host initialisation steps"
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"

    # TODO: This is to be removed once we decide to run it directly from the deploy area
    echo "$FUNCNAME: Copy the proper manage file"
    cp -fv $WMA_DEPLOY_DIR/bin/manage $WMA_MANAGE_DIR/manage && chmod 755 $WMA_MANAGE_DIR/manage

    # Check if the host has a basic WMAgent.secrets file and copy a template if missing
    # NOTE: Here we never overwrite any existing WMAGent.secrets file: We follow:
    #       * Check if there is any at the host, and if so, is it a blank template or a fully configured one
    #       * In case we find a legit WMAgent.secrets file we set the .dockerInit and move on
    #       * In case we need to copy a brand new template (based on the agent type - test/prod )
    #         or a blank one found at the host we halt without updating the .dockerInit file
    #         and we ask the user to examine/update the file.
    #       (Re)Initialization should never pass beyond that step unless properly
    #       configured WMAgent.secrets file being provided at the host.
    echo "$FUNCNAME: Initialise && Validate && Load WMAgent.secrets"
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
        sed -i "s+RUCIO_HOST_OVERWRITE+$RUCIO_HOST+" $WMA_CONFIG_DIR/etc/rucio.cfg
        sed -i "s+RUCIO_AUTH_OVERWRITE+$RUCIO_AUTH+" $WMA_CONFIG_DIR/etc/rucio.cfg
        echo $WMA_BUILD_ID > $wmaInitRucio
    }

    echo "Done: $stepMsg"
    echo "-------------------------------------------------------"

    local stepMsg="Performing local Docker image initialisation steps"
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"

    # Checking Certificates and proxy;
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
        rm -f $wmaInitResourceOpp
        echo "$FUNCNAME: WARNING: NOT cleaning SQL and Couch databases. If you are aware the change in WMAgent.secrets file"
        echo "$FUNCNAME: WARNING: is to affect them, please consider executing 'manage clean-agent' and restart the agent."
        # rm -f $wmaInitCouchDB
        # rm -f $wmaInitSqlDB

    fi
}

_check_oracle() {
    # Auxiliary function to check if the oracle database configured for the current agent is empty
    # NOTE: Oracle is centraly provided - we require an empty database for every account/agent
    #       otherwise we cannot guarantie this is the only agent to connect to the so configured database
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

check_docker_init() {
    # A function to check all previously populated */.dockerInit files
    # from all previous steps and compare them with the /data/.dockerBuildId
    # if all do not match we cannot continue - we consider configuration/version
    # mismatch between the host and the container

    local initFilesList="
        $wmaInitAdmin
        $wmaInitActive
        $wmaInitAgent
        $wmaInitConfig
        $wmaInitUpload
        $wmaInitResourceControl
        $wmaInitResourceOpp
        $wmaInitCouchDB
        $wmaInitSqlDB
        $wmaInitRucio
        $wmaInitUsing
        "
    local stepMsg="Performing checks for successful Docker initialisation steps..."
    echo "-------------------------------------------------------"
    echo "Start: $stepMsg"
    local dockerInitId=""
    local dockerInitIdValues=""
    local idValue=""
    for initFile in $initFilesList; do
        _init_valid $initFile && idValue=$(cat $initFile 2>&1) || idValue=$initFile
        dockerInitIdValues="$dockerInitIdValues $idValue"
    done
    dockerInitId=$(for id in $dockerInitIdValues; do echo $id; done |sort|uniq)
    echo "WMA_BUILD_ID: $WMA_BUILD_ID"
    echo "dockerInitId: $dockerInitId"
    [[ $dockerInitId == $WMA_BUILD_ID ]] && { echo "OK"; return $(true) ;} || { echo "WARNING: dockerInit vs buildId mismatch"; return $(false) ;}
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

        echo "$FUNCNAME: Making agent configuration changes needed for Docker"
        # make this a docker agent
        sed -i "s+Agent.isDocker = False+Agent.isDocker = True+" $WMA_CONFIG_DIR/config.py
        # update the location of submit.sh for docker
        sed -i "s+config.JobSubmitter.submitScript.*+config.JobSubmitter.submitScript = '$WMA_DEPLOY_DIR/etc/submit.sh'+" $WMA_CONFIG_DIR/config.py
        # replace all tags with current
        sed -i "s+$WMA_TAG+current+" $WMA_CONFIG_DIR/config.py

        echo "$FUNCNAME: Making other agent configuration changes"
        sed -i "s+REPLACE_TEAM_NAME+$TEAMNAME+" $WMA_CONFIG_DIR/config.py
        sed -i "s+Agent.agentNumber = 0+Agent.agentNumber = $AGENT_NUMBER+" $WMA_CONFIG_DIR/config.py
        if [[ "$TEAMNAME" == relval ]]; then
            sed -i "s+config.TaskArchiver.archiveDelayHours = 24+config.TaskArchiver.archiveDelayHours = 336+" $WMA_CONFIG_DIR/config.py
        elif [[ "$TEAMNAME" == *testbed* ]] || [[ "$TEAMNAME" == *dev* ]]; then
            GLOBAL_DBS_URL=https://cmsweb-testbed.cern.ch/dbs/int/global/DBSReader
            sed -i "s+DBSInterface.globalDBSUrl = 'https://cmsweb.cern.ch/dbs/prod/global/DBSReader'+DBSInterface.globalDBSUrl = '$GLOBAL_DBS_URL'+" $WMA_CONFIG_DIR/config.py
            sed -i "s+DBSInterface.DBSUrl = 'https://cmsweb.cern.ch/dbs/prod/global/DBSReader'+DBSInterface.DBSUrl = '$GLOBAL_DBS_URL'+" $WMA_CONFIG_DIR/config.py
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
       _init_valid $wmaInitResourceOpp && \
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
        ### Populating opportunistic resource-control
        echo "$FUNCNAME: Populating opportunistic resource-control"
        for res in ${!RESOURCE_*}
        do
            eval `declare -p $res | sed -e "s/$res/site/g"`
            if [[ ${site[name]} =~ .*_US_.* ]] && [[ $HOSTNAME =~ .*cern\.ch ]]; then
                echo "I am based at CERN, so I cannot use US opportunistic resources, moving to the next site"
                continue
            else
                manage execute-agent wmagent-resource-control --plugin=SimpleCondorPlugin --opportunistic --pending-slots=${site[pend]} --running-slots=${site[run]} --add-one-site=${site[name]} ; let errVal+=$?
            fi
        done
        [[ $errVal -eq 0 ]] || { echo "ERROR: Failed to populate WMAgent's opportunistic resource control!"; return $(false) ;}
        echo $WMA_BUILD_ID > $wmaInitResourceOpp
    fi

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

    _init_valid $wmaInitUploaded || {
        echo "$FUNCNAME: triggered."
        echo "$FUNCNAME: Tweaking central agent configuration befre uploading"
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
    check_docker_init || {
        (deploy_to_host)         || { err=$?; echo "ERROR: deploy_to_host"; exit $err ;}
        (check_databases)        || { err=$?; echo "ERROR: check_databases"; exit $err ;}
        (activate_agent)         || { err=$?; echo "ERROR: activate_agent"; exit $err ;}
        (init_agent)             || { err=$?; echo "ERROR: init_agent"; exit $err ;}
        (agent_tweakconfig)      || { err=$?; echo "ERROR: agent_tweakconfig"; exit $err ;}
        (agent_resource_control) || { err=$?; echo "ERROR: agent_resource_control"; exit $err ;}
        (agent_resource_opp)     || { err=$?; echo "ERROR: agent_resource_opp"; exit $err ;}
        (agent_upload_config)    || { err=$?; echo "ERROR: agent_upload_config"; exit $err ;}
        echo $WMA_BUILD_ID > $wmaInitUsing
        (check_docker_init)      || { err=$?; echo "ERROR: DockerBuild vs. HostConfiguration version missmatch"; exit $err ; }
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
        echo "Have a nice day!" && echo
        return $(true)
    }
    (check_databases)            || { err=$?; echo "ERROR: check_databases"; exit $err ;}
    (_renew_proxy)               || { err=$?; echo "ERROR: _renew_proxy"; exit $err ;}
    (start_agent)                || { err=$?; echo "ERROR: start_agent"; exit $err ;}
}

main

exit 0
