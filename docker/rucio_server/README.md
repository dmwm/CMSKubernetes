Steps to create image and push to docker hub

* docker login
* docker build -t rucio_server .
* docker tag rucio_server ericvaandering/rucio_server
* docker push ericvaandering/rucio_server
