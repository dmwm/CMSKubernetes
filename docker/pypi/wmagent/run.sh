#!/bin/bash

### Basic initialization wrapper for WMAgent to serve as the main entry point for the WMAgent Docker container

# Set command prompt for the running user inside the container
cat <<EOF >> ~/.bashrc
export PS1="(WMAgent-\$WMA_TAG) [\u@\h:\W]\$ "
EOF

echo "Start initialization"
./init.sh | tee -a $WMA_LOG_DIR/init.log || true

echo "Start sleeping now ...zzz..."

while true; do sleep 10; done
