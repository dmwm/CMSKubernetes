if [ "$ENVIRONMENT" = "k8s-prod" ]; then
  # Copy the production cron file
  echo "Copying authmap-prod.cron"
  echo "*/15 * * * * /tmp/authmap-prod.sh" > /tmp/authmap.cron
elif [ "$ENVIRONMENT" = "k8s-preprod" ]; then
  # Copy the development cron file
  echo "Copying authmap-preprod.cron"
  echo "*/15 * * * * /tmp/authmap-preprod.sh" > /tmp/authmap.cron
elif [[ "$ENVIRONMENT" == k8s-test* ]]; then
  # Copy the test cron file
  echo "Copying authmap-test.cron"
  echo "*/30 * * * * /tmp/authmap-test.sh" > /tmp/authmap.cron
  
else
  echo "Unsupported environment: $ENVIRONMENT"
  exit 1
fi
