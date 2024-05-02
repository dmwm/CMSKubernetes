# Auxiliary script to hold common function definitions between init.sh and manage scripts

# NOTE: At the current stage none of the global variables like $AGENT_FLAVOR or $MDB_PASS are
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
wmaInitResourceOpp=$WMA_CONFIG_DIR/.initResourceOpp         # set once the resource control of the agent has been populated for opportunistic resources
wmaInitUpload=$WMA_CONFIG_DIR/.initUpload                   # set once the agent config has been uploaded to central CouchDB
wmaInitRuntime=$WMA_CONFIG_DIR/.initRuntime                 # set once the runtime scripts needed for HTCondor are copied at the host
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
        mysql -sN -u $MDB_USER --password=$MDB_PASS -h $MDB_HOST --database=$dbName --execute="$sqlStr"
    else
        mysql -sN -u $MDB_USER --password=$MDB_PASS -h $MDB_HOST --execute="$sqlStr"
    fi

    ## TODO: To add the same functionality for recognizing the type of call, similar to _exec_oracle
    #
    # if $isPipe || $noArgs
    # then
    #     mysql -u $MDB_USER --password=$MDB_PASS -h $MDB_HOST --database=$wmaDBName --pager='less -SFX'
    # else
    #     local sqlStr=$1
    #     local dbName=$2
    #     if [[ -n $dbName ]]; then
    #         mysql -sN -u $MDB_USER --password=$MDB_PASS -h $MDB_HOST --database=$dbName --execute="$sqlStr"
    #     else
    #         mysql -sN -u $MDB_USER --password=$MDB_PASS -h $MDB_HOST --execute="$sqlStr"
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
        execStr="$execStr SET ECHO OFF;\n"
        execStr="$execStr SET UNDERLINE OFF;\n"
        execStr="$execStr SET LINESIZE 1024;\n"
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
        ( unset ORACLE_PATH; echo -e $execStr | sqlplus -NOLOGINTIME -S $ORACLE_USER/$ORACLE_PASS@$ORACLE_TNS )
    elif $isPipe || ! $hasArgs; then
        rlwrap -H $WMA_LOG_DIR/.sqlplus_history -pgreen sqlplus $ORACLE_USER/$ORACLE_PASS@$ORACLE_TNS
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
            mysqldump -u $MDB_USER --password=$MDB_PASS -h $MDB_HOST --no-data --skip-dump-date --compact --skip-opt wmagent > $wmaSchemaFile
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
    # :param $1: The database name to be checked. It will be ignored for Oracle (Default: $wmaDBName)
    echo $FUNCNAME: "Checking if the current SQL Database Id matches the WMA_BUILD_ID and hostname of the agent."
    local wmaDBName=${1:-$wmaDBName}
    local dbIdCmd="select init_value from wma_init where init_param='wma_build_id';"
    local dbHostNameCmd="select init_value from wma_init where init_param='hostname';"
    case $AGENT_FLAVOR in
        'oracle')
            local dbId=$(_exec_oracle "$dbIdCmd")
            local dbHostName=$(_exec_oracle "$dbHostNameCmd")
            ;;
        'mysql')
            local dbId=$(_exec_mysql "$dbIdCmd" $wmaDBName)
            local dbHostName=$(_exec_mysql "$dbHostNameCmd" $wmaDBName)
            ;;
        *)
            echo "$FUNCNAME: ERROR: Unknown or not set Agent Flavor"
            return $(false)
            ;;
    esac
    # Perform the check:
    if [[ $dbId == $WMA_BUILD_ID ]] && [[ $dbHostName == $HOSTNAME ]]; then
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
            _exec_mysql "insert into wma_init (init_param, init_value) values ('wma_build_id', '$WMA_BUILD_ID');" $wmaDBName || return
            _exec_mysql "insert into wma_init (init_param, init_value) values ('wma_tag', '$WMA_TAG');"           $wmaDBName || return
            _exec_mysql "insert into wma_init (init_param, init_value) values ('hostname', '$HOSTNAME');"         $wmaDBName || return
            _exec_mysql "insert into wma_init (init_param, init_value) values ('is_active', 'true');"             $wmaDBName || return
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
    mysqladmin -u $MDB_USER --password=$MDB_PASS -h $MDB_HOST  status
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
    _load_wmasecrets

    # Here to find out if the agent is CERN or FNAL and use the proper credentials name for _renew_proxy
    [[ "$TEAMNAME" == Tier0* ]] &&  {
	echo "$FUNCNAME: This is a Tier0 agent"
	local vomsproxyCmd="voms-proxy-init -rfc \
	            -voms cms:/cms/Role=production -valid 168:00 -bits 2048 \
		    -cert $X509_USER_CERT -key $X509_USER_KEY \
                    -out  $X509_USER_PROXY"
	$vomsproxyCmd || {
	    echo "$FUNCNAME: ERROR: Failed to renew invalid myproxy"
	    return $(false)
	}
    return
    }

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

    $myproxyCmd && $vomsproxyCmd
    return $?
}


_parse_wmasecrets(){
    # Auxiliary function to provide basic parsing of the WMAgent.secrets file
    # :param $1: path to WMAgent.secrets file (Default: $WMA_SECRETS_FILE)
    # :param $2: a particular value to check (Default: *)
    local errVal=0
    local value=""
    local secretsFile=${1:-$WMA_SECRETS_FILE}
    local varsToCheck=${2:-""}

    # All variables need to be fetched in lowercase through: ${var,,}
    local badValuesReg="(update-me|updateme|<update-me>|<updateme>|fix-me|fixme|<fix-me>|<fixme>|^$)"
    # local varsToCheck=`awk -F\= '{print $1}' $secretsFile | grep -vE "^[[:blank:]]*#.*$"`

    # Building the list by parsing the secrets file itself.
    [[ -n $varsToCheck ]] || {
       varsToCheck=`grep -v "^[[:blank:]]*#" $secretsFile  |grep \= | awk -F\= '{print $1}'`
    }

    for var in $varsToCheck
    do
        value=`grep -E "^[[:blank:]]*$var" $secretsFile | awk -F\= '{print $2}'`
        [[ ${value,,} =~ $badValuesReg ]] && { echo "$FUNCNAME: ERROR: Bad value for: $var=$value"; let errVal+=1 ;}
    done
    return $errVal
}


#
# Passwords/Secrets handling
#
_load_wmasecrets(){

    # Auxiliary function to parse WMAgent.secrets or MariaDB.secrets files
    # and load a set of variables from them
    # :param $1: Path to WMAgent.secrets or file (Default: $WMA_SECRETS_FILE)
    # :param $2: String with variable names to be checked (Default: *)
    # :return:   Error value if one or more values have been left unset in the secrets file
    local errVal=0
    local value=""
    local secretsFile=${1:-$WMA_SECRETS_FILE}
    local varsToLoad=${2:-""}

    [[ -f $secretsFile ]] || {
        echo "$FUNCNAME: ERROR: Secrets file $secretsFile does not exist"
        echo "$FUNCNAME: ERROR: Either set WMA_SECRETS_FILE environment variable to a valid file or check that $HOME/WMAgent.secrets exists"
        return $(false)
    }

    # If no list of variables to be loaded was given assume all of them.
    # Building the list by parsing the secrets file itself.
    [[ -n $varsToLoad ]] || {
       varsToLoad=`grep -v "^[[:blank:]]*#" $secretsFile  |grep \= | awk -F\= '{print $1}'`
    }

    # Here we validate every variable for itself before loading it
    for varName in $varsToLoad
    do
        _parse_wmasecrets $secretsFile $varName || {
            let errVal+=1
            echo "$FUNCNAME: ERROR: Bad value found for $varName"
            return $errVal
        }
    done

    # Now load them all
    for varName in $varsToLoad
    do
        value=`grep -E "^[[:blank:]]*$varName=" $secretsFile | sed "s/ *$varName=//"`
        if [[ $varName =~ ^RESOURCE_ ]]; then
	    declare -g -A $varName
            eval $varName=$value || {
		echo "$FUNCNAME: ERROR: Could not evaluate: ${varName}=${!varName}"
		return
	    }
	else
            eval $varName='$value' || {
		echo "$FUNCNAME: ERROR: Could not evaluate: ${varName}=${!varName}"
		return
	    }
	fi
	# echo ${varName}=${!varName}
        [[ -n $varName ]] || { echo "$FUNCNAME: ERROR: Empty value for: $varName=$value"; let errVal+=1 ;}
    done

    # Finaly check and set defaults:

    # Relational database settings (mariaDB or oracle)
    if [[ -z $ORACLE_USER ]]; then
        AGENT_FLAVOR=mysql
        MDB_USER=${MDB_USER:-$USER};
        MDB_HOST=${MDB_HOST:-127.0.0.1};
    else
        AGENT_FLAVOR=oracle
        if [[ -z $ORACLE_PASS ]] || [[ -z $ORACLE_TNS ]]; then
            echo "$FUNCNAME: ERROR: Secrets file doesnt contain ORACLE_PASS or ORACLE_TNS"; let errVal+=1
        fi
    fi

    if [[  -z $GRAFANA_TOKEN ]]; then
        echo "$FUNCNAME: ERROR: Secrets file doesnt contain GRAFANA_TOKEN"; let errVal+=1
    fi

    # CouchDB settings
    # if couch ssl certificate not specified check X509_USER_CERT and X509_USER_PROXY
    # if couch ssl key not specified check X509_USER_KEY and X509_USER_PROXY
    COUCH_USER=${COUCH_USER:-wmagentcouch};
    COUCH_HOST=${COUCH_HOST:-127.0.0.1};
    COUCH_CERT_FILE=${COUCH_CERT_FILE:-${X509_USER_CERT:-$X509_USER_PROXY}};
    COUCH_KEY_FILE=${COUCH_KEY_FILE:-${X509_USER_KEY:-$X509_USER_PROXY}};
    if [[ -z $COUCH_PASS ]]; then
        echo "$FUNCNAME: ERROR: Secrets file doesnt contain COUCH_PASS"; let errVal+=1
    fi

    return $errVal
}

_print_settings(){
    echo "-------------- WMA_* environment variables: --------------"
    env |grep ^WMA| sort

    echo "-------------- WMA_SECRETS_FILE  variables: --------------"
    varsToPrint=`grep -v "^[[:blank:]]*#" $WMA_SECRETS_FILE  |grep \= | awk -F\= '{print $1}'`

    for varName in $varsToPrint
    do
        if [[ $varName =~ ^RESOURCE_ ]]; then
            declare -p $varName
        else
            echo $varName=${!varName}
        fi
    done
    echo "---------------------------------------------------------"
}
