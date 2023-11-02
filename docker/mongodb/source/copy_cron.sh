#!/bin/sh

if [ "$ENVIRONMENT" = "prod" ]; then
  cp /data/tools/mongo-prod.cron /data/tools/mongo.cron
elif [ "$ENVIRONMENT" = "preprod" ]; then
  cp /data/tools/mongo-preprod.cron /data/tools/mongo.cron
elif [ "$ENVIRONMENT" = "test" ]; then
  cp /data/tools/mongo-test.cron /data/tools/mongo.cron
else
  echo "Unsupported environment: $ENVIRONMENT"
  exit 1
fi

# Set up the cron job
crontab /data/tools/mongo.cron

