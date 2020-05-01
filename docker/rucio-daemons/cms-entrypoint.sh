#! /bin/bash

# Remove when fixed upstream. Also dockerfiles

if [ "$RUCIO_DAEMON" == "hermes" ]
then
  sendmail -bd 
fi

/start-daemon.sh
