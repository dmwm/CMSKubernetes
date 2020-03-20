/project/awg/cms/CMS_DBS3_PROD_GLOBAL
1482188400 -> `date +'%R' -d "2016-12-20"` 00:00



SELECT * FROM CMS_DBS3_PROD_GLOBAL_OWNER.DATASETS D

SELECT * FROM CMS_DBS3_PROD_GLOBAL_OWNER.blocks B 

SELECT * FROM CMS_DBS3_PROD_GLOBAL_OWNER.files F 

SELECT * FROM CMS_DBS3_PROD_GLOBAL_OWNER.physics_groups G
SELECT * FROM CMS_DBS3_PROD_GLOBAL_OWNER.acquisition_eras AE
SELECT * FROM CMS_DBS3_PROD_GLOBAL_OWNER.processing_eras PE
SELECT * FROM CMS_DBS3_PROD_GLOBAL_OWNER.dataset_access_types A


sqoop import --direct --connect jdbc:oracle:thin:@cmsr-drac10-scan:10121/cmsr.cern.ch --fetch-size 10000 --username hadoop_data_reader --password impala1234 --target-dir /project/awg/cms/CMS_DBS3_PROD_GLOBAL/datasets -m 1 \
--query \
"SELECT * FROM CMS_DBS3_PROD_GLOBAL_OWNER.DATASETS D  where ( D.creation_date < 1482188400  and D.LAST_MODIFICATION_DATE < 1482188400 ) AND
 \$CONDITIONS" \
--fields-terminated-by , --escaped-by \\ --optionally-enclosed-by '\"'


sqoop import --direct --connect jdbc:oracle:thin:@cmsr-drac10-scan:10121/cmsr.cern.ch --fetch-size 10000 --username hadoop_data_reader --password impala1234 --target-dir /project/awg/cms/CMS_DBS3_PROD_GLOBAL/blocks -m 1 \
--query \
"SELECT * FROM CMS_DBS3_PROD_GLOBAL_OWNER.blocks b where ( b.creation_date < 1482188400  and b.LAST_MODIFICATION_DATE < 1482188400 ) and  \$CONDITIONS" \
--fields-terminated-by , --escaped-by \\ --optionally-enclosed-by '\"'

sqoop import --direct --connect jdbc:oracle:thin:@cmsr-drac10-scan:10121/cmsr.cern.ch --fetch-size 10000 --username hadoop_data_reader --password impala1234 --target-dir /project/awg/cms/CMS_DBS3_PROD_GLOBAL/files -m 1 \
--query \
"SELECT * FROM CMS_DBS3_PROD_GLOBAL_OWNER.files f where ( f.creation_date < 1482188400  and f.LAST_MODIFICATION_DATE < 1482188400 ) and  \$CONDITIONS" \
--fields-terminated-by , --escaped-by \\ --optionally-enclosed-by '\"'


sqoop import --direct --connect jdbc:oracle:thin:@cmsr-drac10-scan:10121/cmsr.cern.ch --fetch-size 10000 --username hadoop_data_reader --password impala1234 --target-dir /project/awg/cms/CMS_DBS3_PROD_GLOBAL/physics_groups -m 1 \
--query \
"SELECT * FROM CMS_DBS3_PROD_GLOBAL_OWNER.physics_groups where \$CONDITIONS" \
--fields-terminated-by , --escaped-by \\ --optionally-enclosed-by '\"'


sqoop import --direct --connect jdbc:oracle:thin:@cmsr-drac10-scan:10121/cmsr.cern.ch --fetch-size 10000 --username hadoop_data_reader --password impala1234 --target-dir /project/awg/cms/CMS_DBS3_PROD_GLOBAL/acquisition_eras -m 1 \
--query \
"SELECT * FROM CMS_DBS3_PROD_GLOBAL_OWNER.acquisition_eras ae where ( ae.creation_date < 1482188400 ) and \$CONDITIONS" \
--fields-terminated-by , --escaped-by \\ --optionally-enclosed-by '\"'


sqoop import --direct --connect jdbc:oracle:thin:@cmsr-drac10-scan:10121/cmsr.cern.ch --fetch-size 10000 --username hadoop_data_reader --password impala1234 --target-dir /project/awg/cms/CMS_DBS3_PROD_GLOBAL/processing_eras -m 1 \
--query \
"SELECT * FROM CMS_DBS3_PROD_GLOBAL_OWNER.processing_eras pe where ( pe.creation_date < 1482188400 ) and \$CONDITIONS" \
--fields-terminated-by , --escaped-by \\ --optionally-enclosed-by '\"'

sqoop import --direct --connect jdbc:oracle:thin:@cmsr-drac10-scan:10121/cmsr.cern.ch --fetch-size 10000 --username hadoop_data_reader --password impala1234 --target-dir /project/awg/cms/CMS_DBS3_PROD_GLOBAL/dataset_access_types -m 1 \
--query \
"SELECT * FROM CMS_DBS3_PROD_GLOBAL_OWNER.dataset_access_types at where \$CONDITIONS" \
--fields-terminated-by , --escaped-by \\ --optionally-enclosed-by '\"'
