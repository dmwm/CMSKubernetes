#!/bin/bash
ls *.rules | grep -v test | awk '{split($1,a,"."); print "promtool test rules "a[1]".test"}' | /bin/sh
