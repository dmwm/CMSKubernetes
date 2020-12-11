# set up variables
BASE_PATH=/project/awg/cms/rucio/
JDBC_URL=jdbc:oracle:thin:@cms-nrac-scan.cern.ch:10121/CMSR_CMS_NRAC.cern.ch
USERNAME=TOBEFILLED
PASSWORD=TOBEFILLED
TABLE=cms_rucio_prod.replicas

TZ=UTC
KRB5CCNAME=/tmp/krb5cc_0

/usr/hdp/sqoop/bin/sqoop import -Dmapreduce.job.user.classpath.first=true -Doraoop.timestamp.string=false -D mapred.chil
d.java.opts="-Djava.security.egd=file:/dev/../dev/urandom" --connect $JDBC_URL --username $USERNAME --password $PASSWORD
 --num-mappers 100 --fetch-size 10000 --table $TABLE --as-avrodatafile -z --direct --target-dir $BASE_PATH`date +%Y-%m-%
 d`/replicas
