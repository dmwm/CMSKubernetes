#!/usr/bin/env bash

# Run pylint and pep8 (pycodestyle) over the entire WMCore code base

# Setup the environment
if [[ -f env_unittest_py3.sh ]]
then
    echo "Sourcing a python3 unittest environment"
    source env_unittest_py3.sh
    OUT_FILENAME=pylintpy3.txt
else
    echo "Sourcing a python2 unittest environment"
    source env_unittest.sh
    OUT_FILENAME=pylint.txt
fi

pushd wmcore_unittest/WMCore
export PYTHONPATH=`pwd`/test/python:`pwd`/src/python:$PYTHONPATH

git checkout master
git pull origin

echo "Printing Pylint version"
pylint --version

# Run pylint on the whole code base
pylint --rcfile=standards/.pylintrc -j 2 -f parseable src/python/* test/python/*

# Fix pep8 which has the wrong python executable
echo "#! /usr/bin/env python" > ../pep8
cat `which pep8` >> ../pep8
chmod +x ../pep8

# Run PEP-8 checker but not in pylint format
pycodestyle --format=default --exclude=test/data,.svn,CVS,.bzr,.hg,.git,__pycache__,.tox.

cp ${PEP8_FILENAME} ${HOME}/artifacts/