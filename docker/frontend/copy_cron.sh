if [ "$ENVIRONMENT" = "k8s-prod" ]; then
  # Copy the production cron file
  echo "Copying authmap-prod.cron"
  cp /tmp/authmap-prod.cron /tmp/authmap.cron
elif [ "$ENVIRONMENT" = "k8s-preprod" ]; then
  # Copy the development cron file
  echo "Copying authmap-preprod.cron"
  cp /tmp/authmap-preprod.cron /tmp/authmap.cron
elif [ "$ENVIRONMENT" = "k8s-test" ]; then
  # Copy the test cron file
  echo "Copying authmap-test.cron"
  cp /tmp/authmap-test.cron /tmp/authmap.cron
  
else
  echo "Unsupported environment: $ENVIRONMENT"
  exit 1
fi
