#! /bin/sh

# Download the script to install everything
curl https://raw.githubusercontent.com/dmwm/WMCore/master/test/deploy/deploy_unittest_py3.sh > /home/dmwm/ContainerScripts/deploy_unittest_py3.sh
chmod +x /home/dmwm/ContainerScripts/deploy_unittest_py3.sh
sh /home/dmwm/ContainerScripts/deploy_unittest_py3.sh

echo "export PYTHONPATH=/home/dmwm/wmcore_unittest/WMCore/src/python:\$PYTHONPATH" >> ./env_unittest_py3.sh
# Shut down services so the docker container doesn't have stale PID & socket files
source ./env_unittest_py3.sh
$manage stop-services

