# Auxiliary script to hold common function definitions between init.sh and manage scripts

# NOTE: At the current stage none of the global variables like $AGENT_FLAVOR or $MYSQL_PASS are
#       defined. All of those come not from the environment as $WMA_* variables, but rather
#       from loading the WMAgent.secrets file.  So loading of this script as a primary source
#       with definitions should work, but calling any of those functions without
#       previously loading the WMAgent.secrets file !!! WILL BREAK !!!.


#-------------------------------------------------------------------------------
# Setting some variables common only between manage and init.sh scripts but not
# relevant for the rest of the environment
#
# Setting all initialization files paths:
wmaInitAdmin=$WMA_CONFIG_DIR/.initAdmin                     # set once the admin area is checked (WMAgent is parsed, validated, and loaded)
wmaInitRucio=$WMA_CONFIG_DIR/.initRucio                     # set once the Rucio config is tweaked
wmaInitActive=$WMA_CONFIG_DIR/.initActive                   # set once the agent has been activated for the first time (i.e. a fresh config template copied in the config area)
wmaInitAgent=$WMA_CONFIG_DIR/.initAgent                     # set once the agent has been initialized for the first time with `manage init-agent` and fresh SQL and Couch databases have been created
wmaInitSqlDB=$WMA_CONFIG_DIR/.initSqlDB                     # set once the metadata table `wma_init` has been recorded at the SQL database and a complete schema dump has been preserved at the host mount area
wmaInitCouchDB=$WMA_CONFIG_DIR/.initCouchDB                 # set immediately after agent initialization
wmaInitConfig=$WMA_CONFIG_DIR/.initConfig                   # set upon final WMAgent config file tweaks have been applied
wmaInitResourceControl=$WMA_CONFIG_DIR/.initResourceControl # set once the resource control of the agent has been populated
wmaInitUpload=$WMA_CONFIG_DIR/.initUpload                   # set once the agent config has been uploaded to central CouchDB
wmaInitUsing=$WMA_CONFIG_DIR/.initUsing                     # Final init flag to mark that the agent is fully activated, initialized, and already in use by the system

# Setting database name and schema dump location.
wmaSchemaFile=$WMA_CONFIG_DIR/.wmaSchemaFile.sql
wmaDBName=wmagent
#-------------------------------------------------------------------------------

_exec_mysql() {
    # Auxiliary function to avoid repetitive and long calls to the  mysql command
    # :param $1: SQL command to be executed passed a s single string
    # :param $2: Database to be used for executing the command (the respective mysql parameter is omitted if $2 is not provided)
    local sqlStr=$1
    local dbName=$2
    if [[ -n $dbName ]]; then
        mysql -sN -u $MYSQL_USER --password=$MYSQL_PASS -h $MYSQL_HOST --database=$dbName --execute="$sqlStr"
    else
        mysql -sN -u $MYSQL_USER --password=$MYSQL_PASS -h $MYSQL_HOST --execute="$sqlStr"
    fi

    # if $isPipe || $noArgs
    # then
    #     mysql -u $MYSQL_USER --password=$MYSQL_PASS -h $MYSQL_HOST --database=$wmaDBName --pager='less -SFX'
    # else
    #     local sqlStr=$1
    #     local dbName=$2
    #     if [[ -n $dbName ]]; then
    #         mysql -sN -u $MYSQL_USER --password=$MYSQL_PASS -h $MYSQL_HOST --database=$dbName --execute="$sqlStr"
    #     else
    #         mysql -sN -u $MYSQL_USER --password=$MYSQL_PASS -h $MYSQL_HOST --execute="$sqlStr"
    #     fi
    # fi
}

_exec_oracle() {
    # Auxiliary function to avoid repetitive and long calls to the sqlplus command
    # :param: $@ could be a sql string to execute or a file redirect or a here document

    # We check for input arguments
    local execStr=""
    if [[ -z $* ]]
    then
        local hasArgs=false
    else
        local hasArgs=true
        # Building a default executable string:
        execStr="$execStr SET HEADING OFF;\n"
        execStr="$execStr SET UNDERLINE OFF;\n"
        execStr="$execStr SET FEEDBACK OFF;\n"
        execStr="$execStr SET PAGESIZE 0;\n"
        execStr="$execStr whenever sqlerror exit sql.sqlcode;\n"
        execStr="$execStr $@"
        execStr="${execStr%;};\n"
        execStr="$execStr exit;\n"
    fi

    # First we need to know if we are running through a redirected input
    # if fd 0 (stdin) is open and refers to a terminal - then we are running the script directly, without a pipe
    # if fd 0 (stdin) is open but does not refer to the terminal - then we are running the script through a pipe
    # NOTE: Docker by default redirects stdin
    local isPipe=false
    if [[ -t 0 ]] ; then isPipe=false; else isPipe=true ; fi

    # Then we traverse the callstack to find if the original caller was init.sh
    # if so - we never redirect
    local isInitCall=false
    for callSource in ${BASH_SOURCE[@]}
    do
        [[ $callSource =~ .*init\.sh ]] && isInitCall=true
    done

    if $isInitCall || $hasArgs; then
        echo -e $execStr | sqlplus -NOLOGINTIME -S $ORACLE_USER/$ORACLE_PASS@$ORACLE_TNS
    elif $isPipe || ! $hasArgs; then
        rlwrap -H ~/.sqlplus_history -pgreen sqlplus $ORACLE_USER/$ORACLE_PASS@$ORACLE_TNS
    else
        echo "$FUNCNAME: ERROR: Unhandled type of call with: isPipe: $isPipe &&  noArgs: $noArgs && isInitCall: $isInitCall"
        return $(false)
    fi
}

_init_valid(){
    # Auxiliary function to shorten repetitive compares of .init* files to the current WMA_BUILD_ID
    # :param $1: The full path to the .init* file to be checked.
    local initFile=$1
    [[ -n $initFile ]] && [[ -f $initFile ]] && [[ `cat $initFile` == $WMA_BUILD_ID ]]
}

_sql_dumpSchema(){
    # Auxiliary function to dump the currently deployed schema into a file
    # :param $1: The location where to dump the schema (defaults to global $wmaSchemaFile)
    local wmaSchemaFile=${1:-$wmaSchemaFile}
    echo "$FUNCNAME: Dumping the current SQL schema of database: $wmaDBName to $wmaSchemaFile"
    case $AGENT_FLAVOR in
        'mysql')
            mysqldump -u $MYSQL_USER --password=$MYSQL_PASS -h $MYSQL_HOST --no-data --skip-dump-date --compact --skip-opt wmagent > $wmaSchemaFile
            ;;
        'oracle')
            echo "$FUNCNAME: NOT implemented"
            ;;
        *)
            echo "$FUNCNAME: ERROR: Unknown or not set Agent Flavor"
            return $(false)
            ;;
    esac
}

_sql_schema_valid(){
    # Auxiliary function to check if the currently deployed schema matches the one dumped during wmagent initialization
    echo $FUNCNAME: "Checking the current SQL Database schema integrity."
    local wmaSchemaTmp=/tmp/.wmaSchemaTmp
    _sql_dumpSchema $wmaSchemaTmp
    diff -u $wmaSchemaFile $wmaSchemaTmp
}

_sql_dbid_valid(){
    # Auxiliary function to check if the build Id and hostname recorded in the database matches the $WMA_BUILD_ID
    # :param $1: The database name to be checked (it will be ignored for Oracle)
    echo $FUNCNAME: "Checking if the current SQL Database Id matches the WMA_BUILD_ID and hostname of the agent."
    local wmaDBName=${1:-$wmaDBName}
    case $AGENT_FLAVOR in
        'oracle')
            local sqlCmd="select init_value from wma_init where init_param='wma_build_id';"
            local dbId=$(_exec_oracle "$sqlCmd")
            local sqlCmd="select init_value from wma_init where init_param='hostname';"
            local dbHostname=$(_exec_oracle "$sqlCmd")
            ;;
        'mysql')
            local sqlCmd="select init_value from wma_init where init_param='wma_build_id';"
            local dbId=$(_exec_mysql "$sqlCmd" $wmaDBName)
            local sqlCmd="select init_value from wma_init where init_param='hostname';"
            local dbHostname=$(_exec_mysql "$sqlCmd" $wmaDBName)
            ;;
        *)
            echo "$FUNCNAME: ERROR: Unknown or not set Agent Flavor"
            return $(false)
            ;;
    esac
    # Perform the check:
    if [[ $dbId == $WMA_BUILD_ID ]] && [[ $dbHostname == $HOSTNAME ]]; then
        echo "$FUNCNAME: OK: Database recorded and current agent's init parameters match."
        return $(true)
    else
        echo "$FUNCNAME: WARNING: Database recorded and current agent's init parameters do NOT match."
        return $(false)
    fi
}

_sql_db_isclean(){
    # Auxiliary function to check if a given database is empty
    # :param $1: The database name to be checked (it will be ignored for Oracle)
    echo "$FUNCNAME: Checking if the current SQL Database is clean and empty."
    local wmaDBName=${1:-$wmaDBName}
    case $AGENT_FLAVOR in
        'oracle')
            local sqlCmd="SELECT COUNT(table_name) FROM user_tables;"
            local numTables=$(_exec_oracle "$sqlCmd")
            [[ $numTables -eq 0 ]] || { echo "$FUNCNAME: WARNING: Nonclean database $wmaDBName: numTables=$numTables"; return $(false) ;}
            ;;
        'mysql')
            local sqlCmd="SELECT SCHEMA_NAME   FROM INFORMATION_SCHEMA.SCHEMATA  WHERE SCHEMA_NAME = '$wmaDBName'"
            local dbExists=$(_exec_mysql "$sqlCmd")
            [[ -n $dbExists ]] || { echo "$FUNCNAME: WARNING: Database $wmaDBName does not exist. 'manage init-agent' should be executed before starting the agent."; return $(true) ;}

            local sqlCmd="SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$wmaDBName';"
            local numTables=$(_exec_mysql "$sqlCmd" $wmaDBName)
            [[ $numTables -eq 0 ]] || { echo "$FUNCNAME: WARNING: Nonclean database $wmaDBName: numTables=$numTables"; return $(false) ;}
            ;;
        *)
            echo "$FUNCNAME: ERROR: Unknown or not set Agent Flavor"
            return $(false)
            ;;
    esac
}

_sql_write_agentid(){
    # Auxiliary function to write the current agent build id into the sql database
    echo "$FUNCNAME: Preserving the current WMA_BUILD_ID and HostName at database: $wmaDBName."
    local createCmd="create table wma_init(init_param varchar(100) not null unique, init_value varchar(100) not null);"
    case $AGENT_FLAVOR in
        'oracle')
            echo "$FUNCNAME: Creating wma_init table at database: $wmaDBName"
            _exec_oracle "$createCmd" || return

            echo "$FUNCNAME: Inserting current Agent's build id and hostname at database: $wmaDBName"
            _exec_oracle "insert into wma_init (init_param, init_value) values ('wma_build_id', '$WMA_BUILD_ID');" || return
            _exec_oracle "insert into wma_init (init_param, init_value) values ('wma_tag', '$WMA_TAG');"           || return
            _exec_oracle "insert into wma_init (init_param, init_value) values ('hostname', '$HOSTNAME');"         || return
            _exec_oracle "insert into wma_init (init_param, init_value) values ('is_active', 'true');"             || return
            ;;
        'mysql')
            echo "$FUNCNAME: Creating wma_init table at database: $wmaDBName"
            _exec_mysql "$createCmd" $wmaDBName || return

            echo "$FUNCNAME: Inserting current Agent's build id and hostname at database: $wmaDBName"
            _exec_oracle "insert into wma_init (init_param, init_value) values ('wma_build_id', '$WMA_BUILD_ID');" $wmaDBName || return
            _exec_oracle "insert into wma_init (init_param, init_value) values ('wma_tag', '$WMA_TAG');"           $wmaDBName || return
            _exec_oracle "insert into wma_init (init_param, init_value) values ('hostname', '$HOSTNAME');"         $wmaDBName || return
            _exec_oracle "insert into wma_init (init_param, init_value) values ('is_active', 'true');"             $wmaDBName || return
            ;;
        *)
            echo "$FUNCNAME: ERROR: Unknown or not set Agent Flavor"
            return $(false)
            ;;
    esac
}

_status_of_couch(){
    echo "$FUNCNAME:"
    curl -s $COUCH_HOST:$COUCH_PORT
    local errVal=$?
    [[ $errVal -ne 0 ]] && { echo "$FUNCNAME: ERROR: CouchDB database unreachable!"; return $(false) ;}
    echo "$FUNCNAME: CouchDB connection is OK!"
}

_status_of_mysql(){
    echo "$FUNCNAME:"
    mysqladmin -u $MYSQL_USER --password=$MYSQL_PASS -h $MYSQL_HOST  status
    local errVal=$?
    [[ $errVal -ne 0 ]] && { echo "$FUNCNAME: ERROR: MySQL database unreachable!"; return $(false) ;}
    echo "$FUNCNAME: MySQL connection is OK!"
}

_status_of_oracle(){
    # Auxiliary function to check if the oracle database configured for the current agent is empty
    echo "$FUNCNAME:"
    _exec_oracle "select 1 from dual;"
#	sqlplus $ORACLE_USER/$ORACLE_PASS@$ORACLE_TNS <<EOF
#     whenever sqlerror exit sql.sqlcode;
#     select 1 from dual;
#     exit;
# EOF
    local errVal=$?
    [[ $errVal -ne 0 ]] && { echo "$FUNCNAME: ERROR: Oracle database unreachable!"; return $(false) ;}
    echo "$FUNCNAME: Oracle connection is OK!"
}

_renew_proxy(){
    # Auxiliary function to renew agent proxy
    local hostName=`hostname -f`

    # Here to find out if the agent is CERN or FNAL and use the proper credentials name for _renew_proxy
    if [[ "$hostName" == *cern.ch ]]; then
        local myproxyCredName="amaltaroCERN"
    elif [[ "$hostName" == *fnal.gov ]]; then
        local myproxyCredName="amaltaroFNAL"
    else
        echo "$FUNCNAME: ERROR: Sorry, we do not recognize the network domain of the current host: $hostName"
        return $(false)
    fi

    # Here to forge the myproxy command string to be used for the operation.
    local myproxyCmd="myproxy-get-delegation \
                    -v -l amaltaro -t 168 -s myproxy.cern.ch -k $myproxyCredName -n \
                    -o $WMA_CERTS_DIR/mynewproxy.pem"
    local vomsproxyCmd="voms-proxy-init -rfc \
                    -voms cms:/cms/Role=production -valid 168:00 -bits 2048 -noregen \
                    -cert $WMA_CERTS_DIR/mynewproxy.pem \
                    -key  $WMA_CERTS_DIR/mynewproxy.pem \
                    -out  $WMA_CERTS_DIR/myproxy.pem"

    # Here to check certificates and proxy lifetime and update myproxy if needed:
    local certMinLifetimeHours=168
    local certMinLifetimeSec=$(($certMinLifetimeHours*60*60))

    if [[ -f $WMA_CERTS_DIR/servicecert.pem ]] && [[ -f $WMA_CERTS_DIR/servicekey.pem ]]; then

        echo "$FUNCNAME: Checking Certificate lifetime:"
        local now=$(date +%s)
        local certEndDate=$(openssl x509 -in $WMA_CERTS_DIR/servicecert.pem -noout -enddate)
        certEndDate=${certEndDate##*=}
        echo "$FUNCNAME: Certificate end date: $certEndDate"
        [[ -z $certEndDate ]] && {
            echo "$FUNCNAME: ERROR: Failed to determine certificate end date!"; return $(false) ;}
        certEndDate=$(date --date="$certEndDate" +%s)
        [[ $certEndDate -le $now ]] && {
            echo "$FUNCNAME: ERROR: Expired certificate at $WMA_CERTS_DIR/servicecert.pem!"; return $(false) ;}
        [[ $(($certEndDate -$now)) -le $certMinLifetimeSec ]] && {
            echo "$FUNCNAME: WARNING: The service certificate lifetime is less than certMinLifetimeHours: $certMinLifetimeHours! Please update it ASAP!" ;}

        # Renew myproxy if needed:
        echo "$FUNCNAME: Checking myproxy lifetime:"
        local myproxyEndDate=$(openssl x509 -in $WMA_CERTS_DIR/myproxy.pem -noout -enddate)
        myproxyEndDate=${myproxyEndDate##*=}
        echo "$FUNCNAME: myproxy end date: $myproxyEndDate"
        [[ -n $myproxyEndDate ]] || ($myproxyCmd && $vomsproxyCmd) || {
                echo "$FUNCNAME: ERROR: Failed to renew invalid myproxy"; return $(false) ;}
        myproxyEndDate=$(date --date="$myproxyEndDate" +%s)
        [[ $myproxyEndDate -gt $(($now + 7*24*60*60)) ]] || ($myproxyCmd && $vomsproxyCmd) || {
                echo "$FUNCNAME: ERROR: Failed to renew expired myproxy"; return $(false) ;}

        # Stay safe and always change the service {cert,key} and myproxy mode here:
        sudo chmod 400 $WMA_CERTS_DIR/*
        echo "$FUNCNAME: OK"
    else
        echo "$FUNCNAME: ERROR: We found no service certificate installed at $WMA_CERTS_DIR!"
        echo "$FUNCNAME: ERROR: Please install proper cert and key files before restarting the WMAgent container!"
        return $(false)
    fi
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


#
# Passwords/Secrets handling
#
_load_wmasecrets(){
    if [ "x$WMA_SECRETS_FILE" == "x" ]; then
        WMA_SECRETS_FILE=$HOME/WMAgent.secrets;
    fi
    if [ ! -e $WMA_SECRETS_FILE ]; then
        echo "$FUNCNAME: Password file: $WMA_SECRETS_FILE does not exist"
        echo "$FUNCNAME: Either set WMA_SECRETS_FILE environment variable to a valid file or check that $HOME/WMAgent.secrets exists"
        return 1;
    fi

    _parse_wmasecrets $WMA_SECRETS_FILE || { echo "$FUNCNAME: WARNING: Not loading raw or not updated secrets file at $WMA_SECRETS_FILE"; return $(false) ;}

    local MATCH_ORACLE_USER=`cat $WMA_SECRETS_FILE | grep ORACLE_USER | sed s/ORACLE_USER=//`
    local MATCH_ORACLE_PASS=`cat $WMA_SECRETS_FILE | grep ORACLE_PASS | sed s/ORACLE_PASS=//`
    local MATCH_ORACLE_TNS=`cat $WMA_SECRETS_FILE | grep ORACLE_TNS | sed s/ORACLE_TNS=//`
    local MATCH_GRAFANA_TOKEN=`cat $WMA_SECRETS_FILE | grep GRAFANA_TOKEN | sed s/GRAFANA_TOKEN=//`
    local MATCH_MYSQL_USER=`cat $WMA_SECRETS_FILE | grep MYSQL_USER | sed s/MYSQL_USER=//`
    local MATCH_MYSQL_PASS=`cat $WMA_SECRETS_FILE | grep MYSQL_PASS | sed s/MYSQL_PASS=//`
    local MATCH_MYSQL_HOST=`cat $WMA_SECRETS_FILE | grep MYSQL_HOST | sed s/MYSQL_HOST=//`
    local MATCH_COUCH_USER=`cat $WMA_SECRETS_FILE | grep COUCH_USER | sed s/COUCH_USER=//`
    local MATCH_COUCH_PASS=`cat $WMA_SECRETS_FILE | grep COUCH_PASS | sed s/COUCH_PASS=//`
    local MATCH_COUCH_PORT=`cat $WMA_SECRETS_FILE | grep COUCH_PORT | sed s/COUCH_PORT=//`
    local MATCH_COUCH_HOST=`cat $WMA_SECRETS_FILE | grep COUCH_HOST | sed s/COUCH_HOST=//`
    local MATCH_COUCH_CERT_FILE=`cat $WMA_SECRETS_FILE | grep COUCH_CERT_FILE | sed s/COUCH_CERT_FILE=//`
    local MATCH_COUCH_KEY_FILE=`cat $WMA_SECRETS_FILE | grep COUCH_KEY_FILE | sed s/COUCH_KEY_FILE=//`
    local MATCH_GLOBAL_WORKQUEUE_URL=`cat $WMA_SECRETS_FILE | grep GLOBAL_WORKQUEUE_URL | sed s/GLOBAL_WORKQUEUE_URL=//`
    local MATCH_LOCAL_WORKQUEUE_DBNAME=`cat $WMA_SECRETS_FILE | grep LOCAL_WORKQUEUE_DBNAME | sed s/LOCAL_WORKQUEUE_DBNAME=//`
    local MATCH_WORKLOAD_SUMMARY_URL=`cat $WMA_SECRETS_FILE | grep WORKLOAD_SUMMARY_URL | sed s/WORKLOAD_SUMMARY_URL=//`
    local MATCH_WORKLOAD_SUMMARY_DBNAME=`cat $WMA_SECRETS_FILE | grep WORKLOAD_SUMMARY_DBNAME | sed s/WORKLOAD_SUMMARY_DBNAME=//`
    local MATCH_WMSTATS_URL=`cat $WMA_SECRETS_FILE | grep WMSTATS_URL | sed s/WMSTATS_URL=//`
    local MATCH_REQMGR2_URL=`cat $WMA_SECRETS_FILE | grep REQMGR2_URL | sed s/REQMGR2_URL=//`
    local MATCH_ACDC_URL=`cat $WMA_SECRETS_FILE | grep ACDC_URL | sed s/ACDC_URL=//`
    local MATCH_DBS3_URL=`cat $WMA_SECRETS_FILE | grep DBS3_URL | sed s/DBS3_URL=//`
    local MATCH_DQM_URL=`cat $WMA_SECRETS_FILE | grep DQM_URL | sed s/DQM_URL=//`
    local MATCH_REQUESTCOUCH_URL=`cat $WMA_SECRETS_FILE | grep REQUESTCOUCH_URL | sed s/REQUESTCOUCH_URL=//`
    local MATCH_CENTRAL_LOGDB_URL=`cat $WMA_SECRETS_FILE | grep CENTRAL_LOGDB_URL | sed s/CENTRAL_LOGDB_URL=//`
    local MATCH_WMARCHIVE_URL=`cat $WMA_SECRETS_FILE | grep WMARCHIVE_URL | sed s/WMARCHIVE_URL=//`
    local MATCH_AMQ_CREDENTIALS=`cat $WMA_SECRETS_FILE | grep AMQ_CREDENTIALS | sed s/AMQ_CREDENTIALS=//`
    local MATCH_RUCIO_HOST=`cat $WMA_SECRETS_FILE | grep RUCIO_HOST | sed s/RUCIO_HOST=//`
    local MATCH_RUCIO_AUTH=`cat $WMA_SECRETS_FILE | grep RUCIO_AUTH | sed s/RUCIO_AUTH=//`
    local MATCH_RUCIO_ACCOUNT=`cat $WMA_SECRETS_FILE | grep RUCIO_ACCOUNT | sed s/RUCIO_ACCOUNT=//`
    local MATCH_TEAMNAME=`cat $WMA_SECRETS_FILE | grep TEAMNAME | sed s/TEAMNAME=//`
    local MATCH_AGENT_NUMBER=`cat $WMA_SECRETS_FILE | grep AGENT_NUMBER | sed s/AGENT_NUMBER=//`


    # database settings (mysql or oracle)
    if [ "x$MATCH_ORACLE_USER" == "x" ]; then
        AGENT_FLAVOR=mysql
        MYSQL_USER=${MATCH_MYSQL_USER:-$USER};
        MYSQL_PASS=${MATCH_MYSQL_PASS:-$MYSQL_PASS};
        MYSQL_HOST=${MATCH_MYSQL_HOST:-127.0.0.1};
    else
        AGENT_FLAVOR=oracle
        ORACLE_USER=$MATCH_ORACLE_USER;
        ORACLE_PASS=$MATCH_ORACLE_PASS;
        ORACLE_TNS=$MATCH_ORACLE_TNS;
        if [ "x$ORACLE_PASS" == "x" ] || [ "x$ORACLE_TNS" == "x" ]; then
            echo "$FUNCNAME: Secrets file doesnt contain ORACLE_PASS or ORACLE_TNS";
            exit 1
        fi
    fi

    GRAFANA_TOKEN=${MATCH_GRAFANA_TOKEN:-$GRAFANA_TOKEN};
    if [ "x$GRAFANA_TOKEN" == "x" ]; then
        echo "$FUNCNAME: Secrets file doesnt contain GRAFANA_TOKEN";
        exit 1
    fi

    # basic couch settings
    COUCH_USER=${MATCH_COUCH_USER:-wmagentcouch};
    COUCH_PASS=${MATCH_COUCH_PASS:-$COUCH_PASS};
    if [ "x$COUCH_PASS" == "x" ]; then
        echo "$FUNCNAME: Secrets file doesnt contain COUCH_PASS";
        exit 1
    fi

    COUCH_PORT=${MATCH_COUCH_PORT:-$COUCH_PORT};
    COUCH_HOST=${MATCH_COUCH_HOST:-127.0.0.1};
    # if couch ssl certificate not specified check X509_USER_CERT and X509_USER_PROXY
    COUCH_CERT_FILE=${MATCH_COUCH_CERT_FILE:-${X509_USER_CERT:-$X509_USER_PROXY}};

    # if couch ssl key not specified check X509_USER_KEY and X509_USER_PROXY
    COUCH_KEY_FILE=${MATCH_COUCH_KEY_FILE:-${X509_USER_KEY:-$X509_USER_PROXY}};

    GLOBAL_WORKQUEUE_URL=${MATCH_GLOBAL_WORKQUEUE_URL:-$GLOBAL_WORKQUEUE_URL};

    LOCAL_WORKQUEUE_DBNAME=${MATCH_LOCAL_WORKQUEUE_DBNAME:-$LOCAL_WORKQUEUE_DBNAME};

    WORKLOAD_SUMMARY_URL=${MATCH_WORKLOAD_SUMMARY_URL:-$WORKLOAD_SUMMARY_URL};

    WMSTATS_URL=${MATCH_WMSTATS_URL:-$WMSTATS_URL}

    REQMGR2_URL=${MATCH_REQMGR2_URL:-$REQMGR2_URL}

    ACDC_URL=${MATCH_ACDC_URL:-$ACDC_URL}

    DBS3_URL=${MATCH_DBS3_URL:-$DBS3_URL}

    DQM_URL=${MATCH_DQM_URL:-$DQM_URL}

    REQUESTCOUCH_URL=${MATCH_REQUESTCOUCH_URL:-$REQUESTCOUCH_URL}

    CENTRAL_LOGDB_URL=${MATCH_CENTRAL_LOGDB_URL:-$CENTRAL_LOGDB_URL}

    WMARCHIVE_URL=${MATCH_WMARCHIVE_URL:-$WMARCHIVE_URL}

    AMQ_CREDENTIALS=${MATCH_AMQ_CREDENTIALS:-$AMQ_CREDENTIALS}
    RUCIO_HOST=${MATCH_RUCIO_HOST:-$RUCIO_HOST}
    RUCIO_AUTH=${MATCH_RUCIO_AUTH:-$RUCIO_AUTH}
    RUCIO_ACCOUNT=${MATCH_RUCIO_ACCOUNT:-$RUCIO_ACCOUNT}
    TEAMNAME=${MATCH_TEMANAME:-$TEAMNAME}
    AGENT_NUMBER=${MATCH_AGENT_NUMBER:-$AGENT_NUMBER}
}

_print_settings(){
    env |grep ^WMA| sort
    echo "ORACLE_USER=               $ORACLE_USER               "
    echo "ORACLE_PASS=               $ORACLE_PASS               "
    echo "ORACLE_TNS=                $ORACLE_TNS                "
    echo "GRAFANA_TOKEN=             $GRAFANA_TOKEN             "
    echo "MYSQL_USER=                $MYSQL_USER                "
    echo "MYSQL_PASS=                $MYSQL_PASS                "
    echo "MYSQL_HOST=                $MYSQL_HOST                "
    echo "COUCH_USER=                $COUCH_USER                "
    echo "COUCH_PASS=                $COUCH_PASS                "
    echo "COUCH_PORT=                $COUCH_PORT                "
    echo "COUCH_HOST=                $COUCH_HOST                "
    echo "COUCH_CERT_FILE=           $COUCH_CERT_FILE           "
    echo "COUCH_KEY_FILE=            $COUCH_KEY_FILE            "
    echo "GLOBAL_WORKQUEUE_URL=      $GLOBAL_WORKQUEUE_URL      "
    echo "LOCAL_WORKQUEUE_DBNAME=    $LOCAL_WORKQUEUE_DBNAME    "
    echo "WORKLOAD_SUMMARY_URL=      $WORKLOAD_SUMMARY_URL      "
    echo "WORKLOAD_SUMMARY_DBNAME=   $WORKLOAD_SUMMARY_DBNAME   "
    echo "WMSTATS_URL=               $WMSTATS_URL               "
    echo "REQMGR2_URL=               $REQMGR2_URL               "
    echo "ACDC_URL=                  $ACDC_URL                  "
    echo "DBS3_URL=                  $DBS3_URL                  "
    echo "DQM_URL=                   $DQM_URL                   "
    echo "REQUESTCOUCH_URL=          $REQUESTCOUCH_URL          "
    echo "CENTRAL_LOGDB_URL=         $CENTRAL_LOGDB_URL         "
    echo "WMARCHIVE_URL=             $WMARCHIVE_URL             "
    echo "AMQ_CREDENTIALS=           $AMQ_CREDENTIALS           "
    echo "RUCIO_HOST=                $RUCIO_HOST                "
    echo "RUCIO_AUTH=                $RUCIO_AUTH                "
    echo "RUCIO_ACCOUNT=             $RUCIO_ACCOUNT             "
    echo "TEAMNAME=                  $TEAMNAME                  "
    echo "AGENT_NUMBER=              $AGENT_NUMBER              "
}
