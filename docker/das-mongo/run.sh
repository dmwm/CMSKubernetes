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

port=8230
journal="--nojournal"
journal="--journal"

# fetch das maps
mkdir -p $STAGEDIR
fetchmaps

# start mongo
mkdir -p /data/mongodb/{wtdb,logs}
mongod --config /data/mongodb.conf

# import das maps
das_js_import $STAGEDIR

# mongostat daemon
mongostat --port 8230 --quiet --json 60
