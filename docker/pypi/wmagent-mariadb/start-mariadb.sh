#/bin/bash

### NOTE: !!!! All OF THIS IS TO BE REMOVED !!!!!
###       !!!! NOTHING MUST STAY HERE !!!!
###       THIS IS JUST A PLACEHOLDER OF ALL THE STEPS THAT
###       NEED TO BE PERFORMED AT THE MARIADB DOCKER IMAGE
mariadbRoot=root
mariadbRootPass=fixme
mariadbUser=cmst1
mariadbUserPass=fixme

configDir=/data/srv/mariadb/current/config
dataDir=/data/srv/mariadb/current/install/database
logDir=/data/srv/mariadb/current/logs
socket=/data/srv/mariadb/current/mariadb.sock
agentDb=wmagent

echo -------------------------------------------------------------------------
echo Stopping any previously running mariadb server
# mariadb-admin -u $mariadbRoot --password=$mariadbRootPass -h 127.0.0.1 shutdown
# mariadb-admin -u $mariadbRoot --password=$mariadbRootPass --socket=$socket shutdown
mariadb-admin -u $mariadbUser --socket=$socket shutdown
echo


# echo -------------------------------------------------------------------------
# echo Installing system database
mariadb-install-db --datadir=$dataDir
# echo



manage start-mariadb

# echo -------------------------------------------------------------------------
# echo starting the server
# mariadbd-safe --defaults-extra-file=$configDir/my.cnf \
#       --datadir=$dataDir \
#       --log-bin \
#       --socket=$socket \
#       --log-error=$logDir/error.log \
#       --pid-file=$logDir/mariadbd.pid  &
# echo ...
# sleep 10
# echo



echo -------------------------------------------------------------------------
echo Securing $mariadbRoot and removing temp databases
sudo mariadb-admin -u $mariadbRoot password $mariadbRootPass --socket=$socket
# mariadb-admin -u $mariadbRoot --password=$mariadbRootPass  -h 127.0.0.1 password $mariadbRootPass
# mariadb-secure-installation --socket=$socket
echo

echo -------------------------------------------------------------------------
echo Securing $mariadbUser and removing temp databases
mariadb-admin -u $mariadbUser password $mariadbUserPass --socket=$socket
# mariadb-admin -u $mariadbRoot --password=$mariadbRootPass  -h 127.0.0.1 password $mariadbRootPass
# mariadb-secure-installation --socket=$socket
echo

echo -------------------------------------------------------------------------
echo creating agent databases
echo "Installing WMAgent Database: $agentDb"
mariadb -u $mariadbUser --password=$mariadbUserPass --socket=$socket --execute "create database $agentDb"

echo

echo -------------------------------------------------------------------------
echo creating new users and setting grants
# try to create a user different than root (if it does not already exist), and grant privileges
# we need ${mariadbUser}'@'127.0.0.1 user in paralel to ${mariadbUser}'@'localhost
mariadb -u $mariadbUser --password=$mariadbUserPass --socket=$socket --execute "CREATE USER '${mariadbUser}'@'localhost' IDENTIFIED BY '$mariadbUserPass'"
mariadb -u $mariadbUser --password=$mariadbUserPass --socket=$socket --execute "GRANT ALL ON *.* TO $mariadbUser@localhost WITH GRANT OPTION"
mariadb -u $mariadbUser --password=$mariadbUserPass --socket=$socket --execute "CREATE USER '${mariadbUser}'@'127.0.0.1' IDENTIFIED BY '$mariadbUserPass'"
mariadb -u $mariadbUser --password=$mariadbUserPass --socket=$socket --execute "GRANT ALL ON *.* TO $mariadbUser@127.0.0.1 WITH GRANT OPTION"

echo -------------------------------------------------------------------------
