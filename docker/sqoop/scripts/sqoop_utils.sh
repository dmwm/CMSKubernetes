function setJava()
{
  export PATH="$PATH:/usr/hdp/sqoop/bin/"
  DEFAULT_JAVA_HOME='/usr/lib/jvm/java-1.8.0'
  if [ -z $1 ]
  then
     JAVA_HOME=$DEFAULT_JAVA_HOME
  else
     JAVA_HOME=$1
  fi
  export JAVA_HOME
}

function sendMail()
{

  OUTPUT_ERROR=`cat $1 | egrep -i error`

  SUBJECT="Error in $2 loading [$3]"
  #MAIL=`cat ~/.forward`
  if [[ $OUTPUT_ERROR == *"ERROR"* ]]; then
    (echo "Check file [$1] for more info." && echo "===========" && echo "${OUTPUT_ERROR}") #| mail -s "$SUBJECT" $MAIL
  fi
}

function exit_on_failure()
{
	OUTPUT_ERROR=`cat $TMP_OUT | egrep "ERROR tool.ImportTool: Error during import: Import job failed!"`
        TRANSF_INFO=`cat $TMP_ERR | egrep "mapreduce.ImportJobBase: Transferred"`
        ROWS_TRANSFERED=`grep 'Map output records=0' $TMP_ERR |wc -l `
 
        if [[ $ROWS_TRANSFERED == "1" ]]
        then
           sendMail $LOG_FILE.stderr $SCHEMA $START_DATE
        fi

	if [[ $OUTPUT_ERROR == *"ERROR"* || ! $TRANSF_INFO == *"INFO"* ]]
        then
	   echo "Error occured, check $LOG_FILE"
	   sendMail $LOG_FILE.stdout $SCHEMA $START_DATE
	   sendMail $LOG_FILE.stderr $SCHEMA $START_DATE

           if hdfs dfs -test -e "$BASE_PATH/new"
           then
              hdfs dfs -rm -r -skipTrash $BASE_PATH/new >/dev/null 2>&1
	   fi
	   exit 1
        fi
}

function clean()
{
    kinit -R
    if hdfs dfs -test -e "$BASE_PATH/new"
    then
       hdfs dfs -rm -r -skipTrash $BASE_PATH/new >> $LOG_FILE.cron
	   echo "Removing old $BASE_PATH/new" >> $LOG_FILE.cron
    fi
}
function deploy()
{
    kinit -R
    error=0
    if ! hdfs dfs -test -e "$BASE_PATH/new"
    then
       echo "$BASE_PATH/new DOES NOT EXISTS! Nothing to deploy! " >> $LOG_FILE.cron
       echo "$BASE_PATH/new DOES NOT EXISTS! Nothing to deploy! " >> $LOG_FILE.stderr
       sendMail $LOG_FILE.stderr $SCHEMA $START_DATE
       return
    fi

    if hdfs dfs -test -e "$BASE_PATH/old"
    then
       echo "Removing old $BASE_PATH/old" >> $LOG_FILE.cron
       hdfs dfs -rm -r -skipTrash $BASE_PATH/old >>$LOG_FILE.stderr 2>>$LOG_FILE.stderr
       error=$(($error+$?))
    fi
    if hdfs dfs -test -e "$BASE_PATH/current"
    then
       echo "Moving $BASE_PATH/current to $BASE_PATH/old"  >> $LOG_FILE.cron
       hdfs dfs -mv $BASE_PATH/current $BASE_PATH/old 2>>$LOG_FILE.stderr
       error=$(($error+$?))
    fi
    echo "Deploying $BASE_PATH/new to $BASE_PATH/current"  >> $LOG_FILE.cron
    hdfs dfs -mv $BASE_PATH/new $BASE_PATH/current 2>>$LOG_FILE.stderr
    error=$(($error+$?))

    if [ $error -ne 0 ]
    then
       echo "ERROR Deployment failed!!!">>$LOG_FILE.stderr
       sendMail $LOG_FILE.stderr $SCHEMA $START_DATE
    fi
}

function import_table()
{
   kinit -R
   TABLE=$1
   TMP_OUT=log/$TABLE.stdout
   TMP_ERR=log/$TABLE.stderr

   OUTPUT_FOLDER=$BASE_PATH/new/$TABLE
   Q="SELECT * FROM ${SCHEMA}.$TABLE F where \$CONDITIONS"
   echo "Timerange: $START_DATE to $END_DATE" >> $LOG_FILE.cron
   echo "Folder: $OUTPUT_FOLDER" >> $LOG_FILE.cron
   echo "quering...$Q" >> $LOG_FILE.cron

   echo "sqoop import..."

   sqoop import -Dmapreduce.job.user.classpath.first=true -Ddfs.client.socket-timeout=120000 --direct --connect $JDBC_URL --fetch-size 10000 --username $USERNAME --password $PASSWORD --target-dir $OUTPUT_FOLDER -m 1 --query "$Q" \
   --fields-terminated-by , --escaped-by \\ --optionally-enclosed-by '\"' \
   1>$TMP_OUT 2>$TMP_ERR

  

   cat $TMP_OUT >>$LOG_FILE.stdout
   cat $TMP_ERR >>$LOG_FILE.stderr
   EXIT_STATUS=$?
   exit_on_failure

}



function generateCountQuery
{
	TABS=$1
	i=0
	QUERY=""
	for T in $TABS
	do
      
	  if [ $i -ne 0 ]
	  then 
	    QUERY="$QUERY union all "   
	  fi
	  i=$((i+1))
      QUERY="$QUERY select '$T', count (*) from $SCHEMA.$T"

	done
	QUERY="$QUERY where \$CONDITIONS"
}

function import_tables()
{
   for TABLE_NAME in $1
   do
      import_table $TABLE_NAME
   done
}

function import_counts()
{
   kinit -R
   TABS=$1
   generateCountQuery "$TABS"

   OUTPUT_FOLDER=$BASE_PATH/new/ROW_COUNT
   echo "Timerange: $START_DATE to $END_DATE" >> $LOG_FILE.cron
   echo "Folder: $OUTPUT_FOLDER" >> $LOG_FILE.cron
   echo "quering...$QUERY" >> $LOG_FILE.cron

   sqoop import -Dmapreduce.job.user.classpath.first=true -Ddfs.client.socket-timeout=120000 --direct --connect $JDBC_URL --fetch-size 10000 --username $USERNAME --password $PASSWORD --target-dir $OUTPUT_FOLDER -m 1 --query "$QUERY" \
   --fields-terminated-by , --escaped-by \\ --optionally-enclosed-by '\"' \
   1>>$LOG_FILE.stdout 2>>$LOG_FILE.stderr

   exit_on_failure

}
