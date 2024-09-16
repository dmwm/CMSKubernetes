#!/usr/bin/env bash

# Run pylint over the entire WMCore code base for compatibility checks

source ./env_unittest.sh
pushd wmcore_unittest/WMCore
export PYTHONPATH=`pwd`/test/python:`pwd`/src/python:$PYTHONPATH

git checkout master
git pull origin

# Run the python3 compatibility checkers in python
echo "Printing Pylint version"
pylint --version

# Disable: [W1618(no-absolute-import), ] import missing `from __future__ import absolute_import`
pylint --py3k -j 2 -f parseable -d W1618 src/python/* test/python/*
