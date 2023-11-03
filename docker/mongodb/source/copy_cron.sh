#!/bin/bash

# Print a message to indicate the script is running
echo "copy_cron.sh is running"

if [ "$ENVIRONMENT" = "prod" ]; then
  # Copy the production cron file
  echo "Copying mongo-prod.cron"
  cp /data/tools/mongo-prod.cron /data/tools/mongo.cron
elif [ "$ENVIRONMENT" = "preprod" ]; then
  # Copy the development cron file
  echo "Copying mongo-preprod.cron"
  cp /data/tools/mongo-preprod.cron /data/tools/mongo.cron
elif [ "$ENVIRONMENT" = "test" ]; then
  # Copy the test cron file
  echo "Copying mongo-test.cron"
  cp /data/tools/mongo-test.cron /data/tools/mongo.cron
else
  echo "Unsupported environment: $ENVIRONMENT"
  exit 1
fi

# Set up the cron job
crontab /data/tools/mongo.cron

# Add another cronjob to get kerberos token once everyday
(crontab -l ; echo "0 0 * * * /root/run.sh") | crontab -

