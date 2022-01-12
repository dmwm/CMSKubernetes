#!/bin/bash
set -e

# Imports CMS_RUCIO_PROD.DIDS table for access time of datasets

# Hdfs output path
BASE_PATH=/project/awg/cms/rucio_dids/
TARGET_DIR=$BASE_PATH"$(date +%Y-%m-%d)"

# Oracle jdbc conn
JDBC_URL=jdbc:oracle:thin:@cms-nrac-scan.cern.ch:10121/CMSR_CMS_NRAC.cern.ch
# Rucio table
TABLE=CMS_RUCIO_PROD.DIDS
# sqoop import query
SQL_QUERY="SELECT * FROM ${TABLE} WHERE scope='cms' AND deleted_at IS NULL AND hidden=0 AND \$CONDITIONS"

# Local log file for both sqoop job stdout and stderr
LOG_FILE=log/$(date +'%F_%H%m%S')_$(basename "$0")
# Timezone
TZ=UTC

####
trap 'onFailExit' ERR
onFailExit() {
    echo "Finished with error! Please see logs!"
    echo "Log files: ${LOG_FILE}"
    echo FAILED
    exit 1
}

####
if [ -f /etc/secrets/rucio ]; then
    USERNAME=$(grep username </etc/secrets/rucio | awk '{print $2}')
    PASSWORD=$(grep password </etc/secrets/rucio | awk '{print $2}')
else
    echo "[ERROR] Unable to read Rucio credentials"
    exit 1
fi

# Check sqoop and hadoop executables exist
if ! [ -x "$(command -v hadoop)" ] || ! [ -x "$(command -v sqoop)" ]; then
    echo "[ERROR] It seems 'sqoop' or 'hadoop' is not exist in PATH! Exiting..."
    exit 1
fi

# Start sqoop
echo "[INFO] Sqoob job for Rucio DIDS table is starting.."
echo "[INFO] Rucio table will be imported: ${TABLE}"
echo "[INFO] Import SQL query: ${SQL_QUERY}"
sqoop import \
    -Dmapreduce.job.user.classpath.first=true \
    -Ddfs.client.socket-timeout=120000 \
    --username "$USERNAME" --password "$PASSWORD" \
    -m 1 \
    -z \
    --direct \
    --throw-on-error \
    --connect $JDBC_URL \
    --fetch-size 10000 \
    --as-avrodatafile \
    --target-dir "$TARGET_DIR" \
    --query "$SQL_QUERY" 1>"$LOG_FILE".stdout 2>"$LOG_FILE".stderr

# change permission of HDFS area
hadoop fs -chmod -R o+rx "$TARGET_DIR"

echo "[INFO] Sqoob job for Rucio DIDS table is finished."
echo "[INFO] Output hdfs path : ${TARGET_DIR}"
echo SUCCESS
