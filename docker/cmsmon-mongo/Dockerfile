ARG MONGODBVER=5.0.9
FROM mongo:$MONGODBVER
MAINTAINER Ceyhun Uzunoglu ceyhunuzngl@gmail.com

# Default paths
ADD mongo.conf /config/mongo.conf
ADD ensure-users.js /docker-entrypoint-initdb.d/ensure-users.js
