#!/bin/bash
##H
##H Usage: manage <backup|restore|status|help> <config_file>
##H
##H Available actions:
##H   help        show this help
##H   backup      backup MongoDB
##H   restore     restore MongoDB
##H   status      status of MongoDB backup
#
ACTION=$1
CONFIG=$2
usage()
{
    grep "^##H " < $0 | sed -e "s,##H ,,g"
}
if [ -z "$CONFIG" ]; then
    echo "No configuration file is provided"
    usage
    exit 1
fi

# how to encrypt file with age
# age -i $AGE_KEY --encrypt file.txt > file.encrypted
# how to decrypt encrypted file with age
# age -i $AGE_KEY --decrypt -o f.txt file.encrypted
# or decrypt to stdout
# age -i $AGE_KEY --decrypt -o - file.encrypted

init(){
  if [ -n "`grep USERNAME $CONFIG`" ]; then
      # we have unencrypted config
      URI=`cat $CONFIG | grep URI | sed -e "s,URI=,,g"`
      HOST=`cat $CONFIG | grep HOST | sed -e "s,HOST=,,g"`
      PORT=`cat $CONFIG | grep PORT | sed -e "s,PORT=,,g"`
      AUTHDB=`cat $CONFIG | grep AUTHDB | sed -e "s,AUTHDB=,,g"`
      USERNAME=`cat $CONFIG | grep USERNAME | sed -e "s,USERNAME=,,g"`
      PASSWORD=`cat $CONFIG | grep PASSWORD | sed -e "s,PASSWORD=,,g"`
      BACKUP_DIR=`cat $CONFIG | grep BACKUP_DIR | sed -e "s,BACKUP_DIR=,,g"`
  else
      if [ -z "$AGE_KEY" ]; then
        echo "AGE_KEY environment is not set, please generate appropriate key file"
        echo "using age-keygen and point this environment to it"
        exit 1
      fi
      # we got encrypted config
      URI=`age -i $AGE_KEY --decrypt -o - $CONFIG | grep URI | sed -e "s,URI=,,g"`
      HOST=`age -i $AGE_KEY --decrypt -o - $CONFIG | grep HOST | sed -e "s,HOST=,,g"`
      PORT=`age -i $AGE_KEY --decrypt -o - $CONFIG | grep PORT | sed -e "s,PORT=,,g"`
      AUTHDB=`age -i $AGE_KEY --decrypt -o - $CONFIG | grep AUTHDB | sed -e "s,AUTHDB=,,g"`
      USERNAME=`age -i $AGE_KEY --decrypt -o - $CONFIG | grep USERNAME | sed -e "s,USERNAME=,,g"`
      PASSWORD=`age -i $AGE_KEY --decrypt -o - $CONFIG | grep PASSWORD | sed -e "s,PASSWORD=,,g"`
      BACKUP_DIR=`age -i $AGE_KEY --decrypt -o - $CONFIG | grep BACKUP_DIR | sed -e "s,BACKUP_DIR=,,g"`
  fi
  if [ -z "$USERNAME" ]; then
      echo "Unable to locate USERNAME in $CONFIG"
      exit 1
  fi
  if [ -z "$PASSWORD" ]; then
      echo "Unable to locate PASSWORD in $CONFIG"
      exit 1
  fi
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
}

backup()
{
    # initialize backup parameters
    init

    # Get the current date and time
    DATE=$(date +%Y-%m-%d_%H-%M-%S)
   
    # Loop through each database and run mongodump
    for dbName in "msOutputDBPreProd" "msPileupDBPreProd" "msUnmergedDBPreProd"
    do
        echo "Dumping database: $dbName"
        mongodump -vvv \
            --uri="$URI/$dbName?replicaSet=mongodb-preprod" \
            --username="$USERNAME" \
            --password="$PASSWORD" \
            --authenticationDatabase="$authdb" \
            --out="$BACKUP_DIR/$DATE" \
            --db="$dbName" 
    done
    #sudo find $BACKUP_DIR -mindepth 1 -maxdepth 1 -type d -ctime +10  | xargs sudo rm -rf;
}

restore()
{
    # initialize backup parameters
    init

    # Get the current date and time
    DATE=$(date +%Y-%m-%d_%H-%M-%S)
   
    # Loop through each database and run mongodump
    for dbName in "msOutputDBPreProd" "msPileupDBPreProd" "msUnmergedDBPreProd"
    do
        echo "Dumping database: $dbName"
        mongorestore -vvv \
            --host=$HOST \
            --port=$PORT \
            --username="$USERNAME" \
            --password="$PASSWORD" \
            --db="$dbName" 
    done
    sudo find $BACKUP_DIR -mindepth 1 -maxdepth 1 -type d -ctime +10  | xargs sudo rm -rf;
}

backup_status()
{
    echo "Not implemented yet"
}


# Main routine, perform action requested on command line.
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
