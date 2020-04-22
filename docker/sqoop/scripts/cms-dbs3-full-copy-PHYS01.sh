#!/bin/bash

. $(dirname $0)/sqoop_utils.sh
setJava
##$CONFIG###


export JDBC_URL=$(sed '1q;d' cmsr_cstring)
export USERNAME=$(sed '2q;d' cmsr_cstring)
export PASSWORD=$(sed '3q;d' cmsr_cstring)

export BASE_PATH=${BASE_PATH:-/project/awg/cms/CMS_DBS3_PROD_PHYS01}
export SCHEMA="CMS_DBS3_PROD_PHYS01_OWNER"

export TABLES="RELEASE_VERSIONS PROCESSING_ERAS PROCESSED_DATASETS PRIMARY_DS_TYPES PRIMARY_DATASETS PHYSICS_GROUPS PARAMETER_SET_HASHES OUTPUT_MODULE_CONFIGS \
 MIGRATION_REQUESTS MIGRATION_BLOCKS FILE_OUTPUT_MOD_CONFIGS FILE_DATA_TYPES DBS_VERSIONS DATA_TIERS DATASET_RUNS DATASET_OUTPUT_MOD_CONFIGS DATASET_ACCESS_TYPES \
 BRANCH_HASHES ASSOCIATED_FILES APPLICATION_EXECUTABLES ACQUISITION_ERAS FILE_PARENTS DATASET_PARENTS BLOCK_PARENTS BLOCKS DATASETS FILE_LUMIS FILES"

#############


me=`basename $0`_$$

if [ -n "$1" ]
then
	START_DATE=$1
else
	START_DATE=`date +'%F'`
fi

year=`date +'%Y' -d "$START_DATE"`
month=`date +'%-m' -d "$START_DATE"`
day=`date +'%-d' -d "$START_DATE"`

export START_DATE_S=`date +'%s' -d "$START_DATE"`

export LOG_FILE=log/`date +'%F_%H%m%S'`_`basename $0`

clean

import_tables "$TABLES"

import_counts "$TABLES"

deploy



