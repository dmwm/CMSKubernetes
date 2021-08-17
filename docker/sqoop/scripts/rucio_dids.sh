# Imports CMS_RUCIO_PROD.DIDS table for last access time of datasets
BASE_PATH=/project/awg/cms/rucio_dids/
JDBC_URL=jdbc:oracle:thin:@cms-nrac-scan.cern.ch:10121/CMSR_CMS_NRAC.cern.ch
if [ -f /etc/secrets/rucio ]; then
  USERNAME=$(cat /etc/secrets/rucio | grep username | awk '{print $2}')
  PASSWORD=$(cat /etc/secrets/rucio | grep password | awk '{print $2}')
else
  echo "Unable to read Rucio credentials"
  exit 1
fi
LOG_FILE=log/$(date +'%F_%H%m%S')_$(basename $0)
TABLE=CMS_RUCIO_PROD.DIDS
TZ=UTC
START_DATE=$(date +'%Y-%m-%d' -d "3 months ago")

/usr/hdp/sqoop/bin/sqoop import \
  -Dmapreduce.job.user.classpath.first=true -Ddfs.client.socket-timeout=120000 --direct --connect $JDBC_URL \
  --fetch-size 10000 --username $USERNAME --password $PASSWORD -m 1 \
  --as-avrodatafile -z --direct --target-dir $BASE_PATH$(date +%Y-%m) \
  --query "SELECT * FROM ${TABLE} WHERE accessed_at<=to_date('${START_DATE}','YYYY-MM-DD') AND scope='cms' AND project='Production' AND did_type='D' AND deleted_at IS NULL AND hidden=0 AND \$CONDITIONS" \
  1>$LOG_FILE.stdout 2>$LOG_FILE.stderr

# change permossion of HDFS area
hadoop fs -chmod -R o+rx $BASE_PATH$(date +%Y-%m-%d)
