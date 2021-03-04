#!/bin/bash
# add GitHub repositories for CRABServer and WMCore

# 0. find the crabserver directory
CRABServerDir=`realpath /data/srv/current/sw/*/cms/crabserver`

# 1. find which tags were installed
CRABServerTag=`ls $CRABServerDir`
export PYTHONPATH=$CRABServerDir/$CRABServerTag/lib/python2.7/site-packages
WMCoreTag=`python -c "from WMCore import __version__; print __version__"`

# 2. create directories for repositories and clone
mkdir /data/repos
pushd /data/repos
git clone https://github.com/dmwm/CRABServer.git
git clone https://github.com/dmwm/WMCore.git

# 3. checkout the installed tags
cd CRABServer
git checkout $CRABServerTag
cd ..
cd WMCore
git checkout $WMCoreTag

# 4. hack init.sh to point PYTHONPATH to the GH repos when $RUN_FROM_GH is True
CRABServerInitDir=${CRABServerDir}/${CRABServerTag}/etc/profile.d/
cd ${CRABServerInitDir}
cat init.sh | grep -v PYTHONPATH > new-init.sh
cat << EOF >> new-init.sh
if [ "\$RUN_FROM_GH" = "True" ]; then
  export PYTHONPATH=/data/repos/CRABServer/src/python:/data/repos/WMCore/src/python/:\$PYTHONPATH
else
EOF
cat init.sh | grep PYTHONPATH | sed "s/\[/  \[/" >> new-init.sh
echo "fi" >> new-init.sh
mv new-init.sh init.sh

# 5. all done, reset cwd and exit
popd
