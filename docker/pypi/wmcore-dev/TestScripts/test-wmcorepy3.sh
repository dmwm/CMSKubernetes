#! /bin/bash -e

WORKDIR=/home/cmsbld
CODE=$WORKDIR/WMCore

pushd $WORKDIR

start=`date +%s`

set +x
# load environment
echo "Sourcing a python3 unittest environment"
. $WORKDIR/TestScripts/env_unittest.sh

# load wmagent secrets
. /data/admin/wmagent/WMAgent.secrets

# This is what the production wmagent-mariadb image defines (via WMA_DATABASE) has as of 2024/07/15
# TODO: We should either make an option in the mariadb image to define the default WMA_DATABASE or make a custom test mariadb image
MDB_UNITTEST_DB=wmagent

export DATABASE=mysql://${MDB_USER}:${MDB_PASS}@127.0.0.1/${MDB_UNITTEST_DB}
export COUCHURL="http://${COUCH_USER}:${COUCH_PASS}@${COUCH_HOST}:${COUCH_PORT}"

# ensure db exists
# retry if fails


for i in 1 2 3 4 5; do
    mysql -u ${MDB_USER} -h 127.0.0.1 -p${MDB_PASS} --execute "CREATE DATABASE IF NOT EXISTS ${MDB_UNITTEST_DB}" && break

    echo "Attempt $i failed. Trying again..."
    sleep 5
done

# rucio
export RUCIO_HOST=$RUCIO_HOST
export RUCIO_AUTH=$RUCIO_AUTH
set -x

pushd $CODE

git pull origin master

# use ghprbPullId if triggered from a PR
if [[ ! -z "${ghprbPullId}" ]]; then
    git fetch --tags  https://github.com/dmwm/WMCore.git "+refs/heads/*:refs/remotes/origin/*"
    git config remote.origin.url https://github.com/dmwm/WMCore.git
    git config --add remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    git fetch --tags --quiet  https://github.com/dmwm/WMCore.git "+refs/pull/*:refs/remotes/origin/pr/*"
    export COMMIT=`git rev-parse "origin/pr/$ghprbPullId/merge^{commit}"`
    export LATEST_TAG=`git tag |grep JENKINS| sort | tail -1`

    # First try to merge this PR into the same tag used for the baseline
    # Next try to merge this tag onto current master
    # Finally give up and just test the tip of the branch
    (git checkout $LATEST_TAG && git merge $COMMIT) || (git checkout master && git merge $COMMIT) || git checkout -f $COMMIT
fi

popd

### Some tweaks for the nose run (in practice, there is nothing to change in setup_test.py...)
# working dir includes entire python source - ignore
perl -p -i -e 's/--cover-inclusive//' $CODE/setup_test.py
# cover branches but not external python modules
perl -p -i -e 's/--cover-inclusive/--cover-branches/' $CODE/setup_test.py
perl -p -i -e "s/'--cover-html',//" $CODE/setup_test.py

#export NOSE_EXCLUDE='AlertGenerator'
# timeout tests after 5 mins
#export NOSE_PROCESSES=1
#export NOSE_PROCESS_TIMEOUT=300
#export NOSE_PROCESS_RESTARTWORKER=1

# include FWCore.ParameterSet.Config

export PYTHONPATH=/var/lib/jenkins/additional-library:$PYTHONPATH

# remove old coverage data
coverage erase

# debugging python interpreters
echo "Python version is: " && python --version || true
echo "Python3 version is: " && python3 --version || true

# run test - force success though - failure stops coverage report
rm nosetests*.xml || true
# FIXME Alan on 25/may/2021: ImportError: cannot import name _psutil_linux
#python3 cms-bot/DMWM/TestWatchdog.py &

python3 $CODE/setup.py test --buildBotMode=true --reallyDeleteMyDatabaseAfterEveryTest=true --testCertainPath=$CODE/test/python --testTotalSlices=$SLICES --testCurrentSlice=$SLICE || true #--testCertainPath=test/python/WMCore_t/WMBS_t || true
mv nosetests.xml artifacts/nosetestspy3-$SLICE-$BUILD_ID.xml

# Add these here as they need the same environment as the main run
#FIXME: change so initial coverage command skips external code
# coverage xml -i --include=$PWD/install* || true

end=`date +%s`
runtime=$((end-start))

echo "Total time to test slice $SLICE: $runtime"
