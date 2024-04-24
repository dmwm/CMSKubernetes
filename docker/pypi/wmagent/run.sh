#!/bin/bash

### Basic initialization wrapper for WMAgent to serve as the main entry point for the WMAgent Docker container
wmaUser=`id -un`
wmaGroup=`id -gn`
wmaUserID=`id -u`
wmaGroupID=`id -g`
export WMA_USER=$wmaUser
echo "Running WMAgent container with user: $wmaUser (ID: $wmaUserID) and group: $wmaGroup (ID: $wmaGroupID)"

echo "Correcting ownership for WMA_ROOT_DIR: $WMA_ROOT_DIR"
find $WMA_ROOT_DIR \! \( -user $wmaUser -group $wmaGroup \) -exec chown -f $wmaUser:$wmaGroup '{}' +;

# append the WMAgent user to the mysql group
usermod -aG mysql ${WMA_USER}


echo "Start initialization"
./init.sh | tee -a $WMA_LOG_DIR/init.log || true

echo "Start sleeping now ...zzz..."
sleep infinity
