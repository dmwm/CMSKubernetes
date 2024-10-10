#!/usr/bin/env bash

if [ -z "$ghprbPullId" -o -z "$ghprbTargetBranch" ]; then
  echo "Not all necessary environment variables set: ghprbPullId, ghprbTargetBranch"
  exit 1
fi

echo "$(TZ=GMT date): running pyfutureTest.sh script"
source ./env_unittest.sh

pushd wmcore_unittest/WMCore
export PYTHONPATH=`pwd`/test/python:`pwd`/src/python:${PYTHONPATH}

git config remote.origin.url https://github.com/dmwm/WMCore.git
git fetch origin pull/${ghprbPullId}/merge:PR_MERGE
export COMMIT=`git rev-parse "PR_MERGE^{commit}"`
git checkout -f ${COMMIT}

echo "$(TZ=GMT date): figuring out what are the files that changed"
# Find all the changed files and filter python-only
git diff --name-only  ${ghprbTargetBranch}..${COMMIT} > allChangedFiles.txt
${HOME}/ContainerScripts/IdentifyPythonFiles.py allChangedFiles.txt > changedFiles.txt
git diff-tree --name-status  -r ${ghprbTargetBranch}..${COMMIT} | egrep "^A" | cut -f 2 > allAddedFiles.txt
${HOME}/ContainerScripts/IdentifyPythonFiles.py allAddedFiles.txt > addedFiles.txt
rm -f allChangedFiles.txt allAddedFiles.txt

echo "$(TZ=GMT date): running futurize 1st stage and some fixers"
while read name; do
  futurize -1 $name >> test.patch
  futurize -f execfile -f filter -f raw_input $name >> test.patch || true
  futurize -f idioms $name  >> idioms.patch || true
done <changedFiles.txt

# Get added files and analyze future imports
echo "$(TZ=GMT date): running AnalyzePyFuture.py script"
${HOME}/ContainerScripts/AnalyzePyFuture.py > added.message

cp test.patch idioms.patch added.message ${HOME}/artifacts/
echo "$(TZ=GMT date): done with all tests and copying files over to artifacts!"
popd
