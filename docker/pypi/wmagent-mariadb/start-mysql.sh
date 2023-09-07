#/bin/bash

### NOTE: !!!! All OF THIS IS TO BE REMOVED !!!!!
###       !!!! NOTHING MUST STAY HERE !!!!
###       THIS IS JUST A PLACEHOLDER OF ALL THE STEPS THAT
###       NEED TO BE PERFORMED AT THE MYSQL DOCKER IMAGE
mysqlRoot=root
mysqlRootPass=
mysqlUser=cmst1
mysqlUserPass=

configDir=/data/dockerMount/srv/mysql/current/config
dataDir=/data/dockerMount/srv/mysql/current/install/database
logDir=/data/dockerMount/srv/mysql/current/logs
socket=/data/dockerMount/srv/mysql/current/logs/mysql.sock
agentDb=wmagent

echo -------------------------------------------------------------------------
echo Stopping any previously running mysql server
mysqladmin -u $mysqlRoot --password=$mysqlRootPass -h 127.0.0.1 shutdown
# mysqladmin -u $mysqlRoot --password=$mysqlRootPass --socket=$socket shutdown
echo


echo -------------------------------------------------------------------------
echo Installing system database
mysql_install_db --datadir=$dataDir
echo


echo -------------------------------------------------------------------------
echo starting the server
mysqld_safe --defaults-extra-file=$configDir/my.cnf \
      --datadir=$dataDir \
      --log-bin \
      --socket=$socket \
      --log-error=$logDir/error.log \
      --pid-file=$logDir/mysqld.pid  & # > /dev/null 2>&1 < /dev/null &
echo ...
sleep 10
echo

echo -------------------------------------------------------------------------
echo Securing mysqlRoot and removing temp databases
mysqladmin -u $mysqlRoot password $mysqlRootPass --socket=$socket
mysqladmin -u $mysqlRoot --password=$mysqlRootPass  -h 127.0.0.1 password $mysqlRootPass
# mysql_secure_installation
echo

echo -------------------------------------------------------------------------
echo creating agent databases
echo "Installing WMAgent Database: $agentDb"
mysql -u $mysqlRoot --password=$mysqlRootPass --socket=$socket --execute "create database '$agentDb'"

echo -------------------------------------------------------------------------
echo creating new users
# create a user - different than root and current unix user - and grant privileges
mysql -u $mysqlRoot --password=$mysqlRootPass --socket=$socket --execute "CREATE USER '${mysqlUser}'@'localhost' IDENTIFIED BY '$mysqlUserPass'"
mysql -u $mysqlRoot --password=$mysqlRootPass --socket=$socket --execute "GRANT ALL ON *.* TO $mysqlUser@localhost WITH GRANT OPTION"
mysql -u $mysqlRoot --password=$mysqlRootPass --socket=$socket --execute "CREATE USER '${mysqlUser}'@'127.0.0.1' IDENTIFIED BY '$mysqlUserPass'"
mysql -u $mysqlRoot --password=$mysqlRootPass --socket=$socket --execute "GRANT ALL ON *.* TO $mysqlUser@127.0.0.1 WITH GRANT OPTION"


echo -------------------------------------------------------------------------
