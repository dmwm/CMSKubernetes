#!/bin/bash
set -e

# Imports CMS_RUCIO_PROD.CONTENTS table for access time of datasets

# Hdfs output path
BASE_PATH=/project/awg/cms/rucio_contents/
TARGET_DIR=$BASE_PATH"$(date +%Y-%m-%d)"

# Rucio table name
TABLE=CMS_RUCIO_PROD.CONTENTS
# Oracle jdbc conn
JDBC_URL=jdbc:oracle:thin:@cms-nrac-scan.cern.ch:10121/CMSR_CMS_NRAC.cern.ch

# Log file
LOG_FILE=log/$(date +'%F_%H%m%S')_$(basename "$0")
# Timezone
TZ=UTC

####
trap 'onFailExit' ERR
onFailExit() {
    echo "Finished with error!" >>"$LOG_FILE".stdout
    echo "Log files: ${LOG_FILE}" >>"$LOG_FILE".stdout
    echo FAILED
    exit 1
}

####
if [ -f /etc/secrets/rucio ]; then
    USERNAME=$(grep username </etc/secrets/rucio | awk '{print $2}')
    PASSWORD=$(grep password </etc/secrets/rucio | awk '{print $2}')
else
    echo "Unable to read Rucio credentials" >>"$LOG_FILE".stdout
    exit 1
fi

# Check sqoop and hadoop executables exist
if ! [ -x "$(command -v hadoop)" ]; then
    echo "It seems 'hadoop' is not exist in PATH! Exiting..." >>"$LOG_FILE".stdout
    exit 1
fi

echo "[INFO] Sqoob job for Rucio CONTENTS table is starting.." >>"$LOG_FILE".stdout
echo "[INFO] Rucio table will be imported: ${TABLE}" >>"$LOG_FILE".stdout
# Start sqoop import
/usr/hdp/sqoop/bin/sqoop import \
    -Dmapreduce.job.user.classpath.first=true \
    -Doraoop.timestamp.string=false \
    -Dmapred.child.java.opts="-Djava.security.egd=file:/dev/../dev/urandom" \
    -Ddfs.client.socket-timeout=120000 \
    --username "$USERNAME" --password "$PASSWORD" \
    -z \
    --direct \
    --throw-on-error \
    --connect $JDBC_URL \
    --num-mappers 100 \
    --fetch-size 10000 \
    --as-avrodatafile \
    --target-dir "$TARGET_DIR" \
    --table "$TABLE" 1>"$LOG_FILE".stdout 2>"$LOG_FILE".stderr

# change permission of HDFS area
hadoop fs -chmod -R o+rx "$TARGET_DIR"

{
    echo "[INFO] Sqoob job for Rucio CONTENTS table is finished."
    echo "[INFO] Output hdfs path : ${TARGET_DIR}"
    echo "SUCCESS"
} >>"$LOG_FILE".stdout
