# set up variables
BASE_PATH=/project/awg/cms/rucio/
JDBC_URL=jdbc:oracle:thin:@cms-nrac-scan.cern.ch:10121/CMSR_CMS_NRAC.cern.ch
if [ -f /etc/secrets/rucio ]; then
    USERNAME=`cat /etc/secrets/rucio | grep username | awk '{print $2}'`
    PASSWORD=`cat /etc/secrets/rucio | grep password | awk '{print $2}'`
else
    echo "Unable to read Rucio credentials"
    exit 1
fi
LOG_FILE=log/`date +'%F_%H%m%S'`_`basename $0`
TABLE=cms_rucio_prod.replicas
TZ=UTC

/usr/hdp/sqoop/bin/sqoop import -Dmapreduce.job.user.classpath.first=true \
    -Doraoop.timestamp.string=false \
    -Dmapred.child.java.opts="-Djava.security.egd=file:/dev/../dev/urandom" \
    --connect $JDBC_URL --username $USERNAME --password $PASSWORD  \
    --num-mappers 100 --fetch-size 10000 --table $TABLE --as-avrodatafile \
    -z --direct --target-dir $BASE_PATH`date +%Y-%m-%d`/replicas \
1>$LOG_FILE.stdout 2>$LOG_FILE.stderr

# change permossion of HDFS area
hadoop fs -chmod -R o+rx $BASE_PATH`date +%Y-%m-%d`
