#!/bin/bash

DAS_ROOT=/data
STAGEDIR=/data/stagedir
DASMAPS_DIR=$STAGEDIR/DASMaps

fetchmaps(){
  set -e
  DASMAPS_URL="https://raw.githubusercontent.com/dmwm/DASMaps/master/js"
  mkdir -p $DASMAPS_DIR
  das_js_fetch $DASMAPS_URL $DASMAPS_DIR

  # validate DAS maps
  das_js_validate $DASMAPS_DIR

  # clean-up STEGEDIR area
  rm -f $STAGEDIR/*.js $STAGEDIR/*-schema-stamp

  # copy DAS maps into STAGEDIR
  cp -r $DASMAPS_DIR/* $STAGEDIR

  # mark that we updated MongoDB with DAS maps
  echo "Fetched maps: `date`" > $STAGEDIR/das_maps_status

  # clean-up DASMAPS_DIR
  rm -rf $DASMAPS_DIR

  set +e
}

# fetch das maps
mkdir -p $STAGEDIR
fetchmaps

# start mongo
mkdir -p /data/mongodb/{wtdb,logs}
if [ -f /etc/secrets/mongodb.conf ]; then
    mongod --config /etc/secrets/mongodb.conf
else
    mongod --config /data/mongodb.conf
fi

# import das maps
if [ -f /etc/secrets/frontend ]; then
    fe=`cat /etc/secrets/frontend`
    ls $STAGEDIR/*.js | awk '{print "sed -i -e \"s,cmsweb.cern.ch,"fe",g\" "$1""}' fe=$fe | /bin/sh
fi
if [ -f /etc/secrets/dasmap ]; then
    if [ -n "grep testbed in $fe" ]; then
        dasmap=`cat /etc/secrets/dasmap`
        cp -f $STAGEDIR/$dasmap $STAGEDIR/update_mapping_db.js
    fi
fi
das_js_import $STAGEDIR

# mongostat daemon
mongostat --port 8230 --quiet --json 60
