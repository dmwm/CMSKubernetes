# Imports CMS_RUCIO_PROD.CONTENTS table for access time of datasets
BASE_PATH=/project/awg/cms/rucio_contents/
JDBC_URL=jdbc:oracle:thin:@cms-nrac-scan.cern.ch:10121/CMSR_CMS_NRAC.cern.ch
if [ -f /etc/secrets/rucio ]; then
  USERNAME=$(grep username </etc/secrets/rucio | awk '{print $2}')
  PASSWORD=$(grep password </etc/secrets/rucio | awk '{print $2}')
else
  echo "Unable to read Rucio credentials"
  exit 1
fi

# There should be always one folder
PREVIOUS_FOLDER=$(hadoop fs -ls $BASE_PATH | awk '{ORS=""; print $8}')
LOG_FILE=log/$(date +'%F_%H%m%S')_$(basename "$0")
TABLE=CMS_RUCIO_PROD.CONTENTS
TZ=UTC

# Check sqoop and hadoop executables exist
if ! [ -x "$(command -v hadoop)" ] || ! [ -x "$(command -v sqoop)" ]; then
  echo "It seems 'sqoop' or 'hadoop' is not exist in PATH! Exiting..."
  exit 1
fi

sqoop import \
  -Dmapreduce.job.user.classpath.first=true \
  -Ddfs.client.socket-timeout=120000 \
  --username "$USERNAME" --password "$PASSWORD" \
  -m 1 \
  -z \
  --direct \
  --connect $JDBC_URL \
  --fetch-size 10000 \
  --as-avrodatafile \
  --target-dir "$BASE_PATH""$(date +%Y-%m-%d)" \
  --query "SELECT * FROM ${TABLE} WHERE did_type='D' AND child_type='F' AND \$CONDITIONS" \
  1>"$LOG_FILE".stdout 2>"$LOG_FILE".stderr

# change permission of HDFS area
hadoop fs -chmod -R o+rx $BASE_PATH"$(date +%Y-%m-%d)"

# Delete previous folder
hadoop fs -rmdir --ignore-fail-on-non-empty "$PREVIOUS_FOLDER"
echo "$PREVIOUS_FOLDER is deleted"
