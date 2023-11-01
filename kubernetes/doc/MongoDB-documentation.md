Action items top MongoDB backup/restore procedure:
- Valentin: add amtool and email to mongodb image and test that we can send alerts
- Aroosha:
  - write documentation about restore procedure
  - Add description how to restore from particular backup date and specific database
- Muhammad/Aroosha perform test procedure on test mongodb
  - crash MOngoDB
  - restore
  - use mongo tool to access database
  - https://www.mongodb.com/docs/mongodb-shell/run-commands/


These items are independent from MongoDB itself and can be applied to everything in k8s world

- Muhammad
  - review tool which monitor pod/node crashes and add to this tool ability to notify operator
  - if it is not there, add ability to this too to send notification when pod/node has crashed
 
About kerberos
- create keytab file using your credentials
- using monitoring exporter to monitor expiration of keytab
- I also provided a tool to CMS monitoring team to check validity of keytab, please see http-exporter-certchec.yaml and PR#1270 where it was introduced.
