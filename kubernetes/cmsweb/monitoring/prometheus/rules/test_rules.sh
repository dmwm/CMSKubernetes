#!/bin/bash
echo "Testing service rules..."
ls *.rules | grep -v test_rules | awk '{print "promtool check rules "$1""}' | /bin/sh
echo "Perform service alert tests..."
ls *.test | grep -v test_rules | awk '{print "promtool test rules "$1""}' | /bin/sh
