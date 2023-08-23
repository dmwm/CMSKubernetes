#!/bin/bash

### Basic initialization wrapper for WMAgent to serve as the main entry point for the WMAgent Docker container


echo "Start initialization"
./run.sh || true

echo "Start sleeping now ...zzz..."

while true; do sleep 10; done
