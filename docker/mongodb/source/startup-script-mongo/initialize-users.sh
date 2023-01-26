#!/bin/bash

echo "Executing initialize-users.sh"

while [[ ( "$(mongo --quiet --eval "rs.status().ok")" != "1" ) || ! ( "$(mongo --quiet --eval "rs.status().members[0].state")" == "1" || "$(mongo --quiet --eval "rs.status().members[1].state")" == "1" || "$(mongo --quiet --eval "rs.status().members[2].state")" == "1" ) ]]
do
    echo "MongoDB not ready for user creation, retrying in 5 seconds..."
    sleep 5
done

if [[ "$(mongo --quiet --eval "db.isMaster().ismaster")" == "true" ]]
then
echo "Primary node found, creating users"
mongo --eval "adminpass = '$MONGODB_ADMIN_PASSWORD'" --shell << EOL
use admin
db.createUser(
  {
    user: "usersAdmin",
    pwd: adminpass,
    roles: [ { role: "userAdminAnyDatabase", db: "admin" } ]
  }
)
db.auth("usersAdmin", adminpass)
db.getSiblingDB("admin").createUser(
  {
    "user" : "clusterAdmin",
    "pwd" : adminpass,
    roles: [ { "role" : "clusterAdmin", "db" : "admin" } ]
  }
)
EOL
else
    echo "Replica Set not primary..."
fi
