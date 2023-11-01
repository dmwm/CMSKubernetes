#!/bin/bash

##H
##H Usage: manage <backup|restore|status|help> <config_file>
##H
##H Available actions:
##H   help        show this help
##H   backup      backup MongoDB
##H   restore     restore MongoDB
##H   status      status of MongoDB backup

ACTION=$1
CONFIG=$2

usage() {
    grep "^##H " < "$0" | sed -e "s,##H ,,g"
}

if [ -z "$CONFIG" ]; then
    echo "No configuration file is provided"
    usage
    exit 1
fi

init() {
    if [ -n "$(grep USERNAME "$CONFIG")" ]; then
        # we have unencrypted config
        URI=$(cat "$CONFIG" | grep URI | sed -e "s,URI=,,g")
        HOST=$(cat "$CONFIG" | grep HOST | sed -e "s,HOST=,,g")
        PORT=$(cat "$CONFIG" | grep PORT | sed -e "s,PORT=,,g")
        AUTHDB=$(cat "$CONFIG" | grep AUTHDB | sed -e "s,AUTHDB=,,g")
        USERNAME=$(cat "$CONFIG" | grep USERNAME | sed -e "s,USERNAME=,,g")
        PASSWORD=$(cat "$CONFIG" | grep PASSWORD | sed -e "s,PASSWORD=,,g")
        BACKUP_DIR=$(cat "$CONFIG" | grep BACKUP_DIR | sed -e "s,BACKUP_DIR=,,g")
        RS_NAME=$(cat "$CONFIG" | grep RS_NAME | sed -e "s,RS_NAME=,,g")
        DB_NAMES=$(cat "$CONFIG" | grep DB_NAMES | sed -e "s,DB_NAMES=,,g")
    else
        if [ -z "$AGE_KEY" ]; then
            echo "AGE_KEY environment is not set, please generate an appropriate key file"
            echo "using age-keygen and point this environment to it"
            exit 1
        fi
        # we got encrypted config
        URI=$(age -i "$AGE_KEY" --decrypt -o - "$CONFIG" | grep URI | sed -e "s,URI=,,g")
        HOST=$(age -i "$AGE_KEY" --decrypt -o - "$CONFIG" | grep HOST | sed -e "s,HOST=,,g")
        PORT=$(age -i "$AGE_KEY" --decrypt -o - "$CONFIG" | grep PORT | sed -e "s,PORT=,,g")
        AUTHDB=$(age -i "$AGE_KEY" --decrypt -o - "$CONFIG" | grep AUTHDB | sed -e "s,AUTHDB=,,g")
        USERNAME=$(age -i "$AGE_KEY" --decrypt -o - "$CONFIG" | grep USERNAME | sed -e "s,USERNAME=,,g")
        PASSWORD=$(age -i "$AGE_KEY" --decrypt -o - "$CONFIG" | grep PASSWORD | sed -e "s,PASSWORD=,,g")
        BACKUP_DIR=$(age -i "$AGE_KEY" --decrypt -o - "$CONFIG" | grep BACKUP_DIR | sed -e "s,BACKUP_DIR=,,g")
        RS_NAME=$(age -i "$AGE_KEY" --decrypt -o - "$CONFIG" | grep RS_NAME | sed -e "s,RS_NAME=,,g")
    fi

    if [ -z "$USERNAME" ]; then
        echo "Unable to locate USERNAME in $CONFIG"
        exit 1
    fi
    if [ -z "$PASSWORD" ]; then
        echo "Unable to locate PASSWORD in $CONFIG"
        exit 1
    }
    if [ -z "$RS_NAME" ]; then
        echo "Unable to locate RS_NAME in $CONFIG"
        exit 1
    }
    if [ "$ACTION" == "backup" ]; then
        if [ -z "$URI" ]; then
            echo "Unable to locate URI in $CONFIG"
            exit 1
        fi
        if [ -z "$AUTHDB" ]; then
            echo "Unable to locate AUTHDB in $CONFIG"
            exit 1
        fi
        if [ -z "$BACKUP_DIR" ]; then
            echo "Unable to locate BACKUP_DIR in $CONFIG"
            exit 1
        fi
    fi
    if [ "$ACTION" == "restore" ]; then
        if [ -z "$HOST" ]; then
            echo "Unable to locate HOST in $CONFIG"
            exit 1
        fi
        if [ -z "$PORT" ]; then
            echo "Unable to locate PORT in $CONFIG"
            exit 1
        fi
    fi
    # Split DB_NAMES into an array
    IFS=' ' read -ra DB_NAME_ARRAY <<< "$DB_NAMES"
    # selecting backup directory based on the deployment name
    BACKUP_DIR="$BACKUP_DIR/$MONGODB_ID"
}

backup() {
    # Initialize backup parameters
    init

    # Get the current date and time
    DATE=$(date +%Y-%m-%d_%H-%M-%S)

    for dbName in "${DB_NAME_ARRAY[@]}"
    do
        echo "Dumping database: $dbName"
    
        mongodump --uri "mongodb://$USERNAME:$PASSWORD@$URI/$dbName?replicaSet=$RS_NAME" --authenticationDatabase="$AUTHDB" --out="$BACKUP_DIR/$DATE"
    done

    find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d -ctime +10 | xargs rm -rf
}

restore() {
    # Initialize restore parameters
    init

    # Get the current date and time
    DATE=$(date +%Y-%m-%d_%H-%M-%S)

    for dbName in "${DB_NAME_ARRAY[@]}"
    do
        echo "Restoring database: $dbName"

        mongorestore --uri "mongodb://$USERNAME:$PASSWORD@$URI/$dbName?replicaSet=$RS_NAME" --authenticationDatabase="$AUTHDB" "$BACKUP_DIR/$DATE"
    done
}

backup_status() {
    echo "Not implemented yet"
}

# Main routine, perform action requested on the command line.
case ${1:-status} in
  backup )
    backup
    ;;

  restore )
    restore
    ;;

  status )
    backup_status
    ;;

  help )
    usage
    ;;

  * )
    echo "$0: unknown action '$1', please try '$0 help' or documentation." 1>&2
    exit 1
    ;;
esac

