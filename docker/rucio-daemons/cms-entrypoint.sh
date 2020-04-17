#! /bin/bash

if [ "$RUCIO_DAEMON" == "hermes" ]
then
  sendmail -bd 
fi

/start-daemon.sh
