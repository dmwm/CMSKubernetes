#!/usr/bin/env bash

WORKDIR=/home/cmsbld

if [ -z "$ghprbPullId" -o -z "$ghprbTargetBranch" ]; then
  echo "Not all necessary environment variables set: ghprbPullId, ghprbTargetBranch"
  exit 1
fi

echo "Executing Pylint for PR ID $ghprbPullId and target branch $ghprbTargetBranch"

# Setup the environment
echo "Sourcing a python3 unittest environment"
source $WORKDIR/TestScripts/env_unittest.sh
JSON_FILENAME=pylintpy3Report.json
PEP8_FILENAME=pep8py3.txt

pushd $WORKDIR/WMCore
export PYTHONPATH=`pwd`/test/python:`pwd`/src/python:$PYTHONPATH

# Figure out the one commit we are interested in and what happens to the repo if we were to merge it
git config remote.origin.url https://github.com/dmwm/WMCore.git
git fetch origin pull/${ghprbPullId}/merge:PR_MERGE
export COMMIT=`git rev-parse "PR_MERGE^{commit}"`
git checkout ${ghprbTargetBranch}
git pull

# Which python files changed?
git diff --name-only  ${ghprbTargetBranch}..${COMMIT} > allChangedFiles.txt
$WORKDIR/ContainerScripts/IdentifyPythonFiles.py allChangedFiles.txt > changedFiles.txt

echo "Printing Pylint version"
pylint --version

# Get pylint report for master
git checkout -f $ghprbTargetBranch
echo "{}" > pylintReport.json
echo "*** Running Pylint on the changed files against the $ghprbTargetBranch"
while read name; do
  pylint --evaluation='10.0 - ((float(5 * error + warning) / statement) * 10)'  --rcfile standards/.pylintrc --msg-template='{path}:{line}: [{msg_id}({symbol}), {obj}] {msg}'  $name > pylint.out || true
  $WORKDIR/ContainerScripts/AggregatePylint.py base
done <changedFiles.txt

# Get pylint report for the tip of our branch
git checkout -f $COMMIT
echo "*** Running Pylint on the changed files against the feature branch"
while read name; do
  pylint --evaluation='10.0 - ((float(5 * error + warning) / statement) * 10)'  --rcfile standards/.pylintrc  --msg-template='{path}:{line}: [{msg_id}({symbol}), {obj}] {msg}'  $name  > pylint.out || true
  $WORKDIR/ContainerScripts/AggregatePylint.py test
done <changedFiles.txt

# Save the artifacts to a directory shared by the container and the node
# update file if it's a python3 pylint job
mv pylintReport.json ${JSON_FILENAME} || true
cp *.json $WORKDIR/artifacts/

touch NOTHING # If changedFiles.txt is empty, this will keep it from parsing the whole directory tree
pycodestyle NOTHING `< changedFiles.txt` > ${PEP8_FILENAME}
cp ${PEP8_FILENAME} $WORKDIR/artifacts/

popd
