#!/bin/bash

### Basic initialization wrapper for WMAgent to serve as the main entry point for the WMAgent Docker container


echo "Start initialization"
./init.sh | tee -a $WMA_LOG_DIR/init.log || true

echo "Start sleeping now ...zzz..."

while true; do sleep 10; done
