select 

    files.FILE_ID,
    files.LOGICAL_FILE_NAME,
    files.IS_FILE_VALID,
    files.FILE_TYPE_ID,
    files.CHECK_SUM,
    files.EVENT_COUNT,
    files.FILE_SIZE,
    files.BRANCH_HASH_ID,
    files.ADLER32,
    files.MD5,
    files.AUTO_CROSS_SECTION,
    
    blocks.BLOCK_ID,
    blocks.BLOCK_NAME,
    blocks.DATASET_ID,
    blocks.OPEN_FOR_WRITING,
    blocks.ORIGIN_SITE_NAME,
    blocks.BLOCK_SIZE,
    blocks.FILE_COUNT,
    blocks.CREATION_DATE,
    blocks.CREATE_BY,
    blocks.LAST_MODIFICATION_DATE,
    blocks.LAST_MODIFIED_BY,
    
    datasets.DATASET_ID,
    datasets.DATASET,
    datasets.IS_DATASET_VALID,
    datasets.PRIMARY_DS_ID,
    datasets.PROCESSED_DS_ID,
    datasets.DATA_TIER_ID,
    datasets.DATASET_ACCESS_TYPE_ID,
    datasets.ACQUISITION_ERA_ID,
    datasets.PROCESSING_ERA_ID,
    datasets.PHYSICS_GROUP_ID,
    datasets.XTCROSSSECTION,
    datasets.PREP_ID,
    datasets.CREATION_DATE,
    datasets.CREATE_BY,
    datasets.LAST_MODIFICATION_DATE,
    datasets.LAST_MODIFIED_BY,
    
    files.CREATION_DATE,
    files.CREATE_BY,
    files.LAST_MODIFICATION_DATE,
    files.LAST_MODIFIED_BY,


from 
    CMS_DBS3_PROD_GLOBAL_OWNER.FILES files,
    CMS_DBS3_PROD_GLOBAL_OWNER.BLOCKS blocks,
    CMS_DBS3_PROD_GLOBAL_OWNER.DATASETS datasets

where
    files.BLOCK_ID = blocks.BLOCK_ID and
    files.DATASET_ID = datasets.DATASET_ID and 
    ( 
        ( files.CREATION_DATE >= $startTS and files.CREATION_DATE < $endTS )
        or
        ( files.LAST_MODIFICATION_DATE >= $startTS and files.LAST_MODIFICATION_DATE < $endTS )
    )