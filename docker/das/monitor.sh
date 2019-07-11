#!/bin/bash
# start das exporters
nohup das2go_exporter -address ":18217" 2>&1 1>& das2go_exporter.log < /dev/null &
# we need to build first mongodb_exporter
nohup mongodb_exporter -mongodb.uri mongodb://localhost:8230 --web.listen-address ":18230" 2>&1 1>& mongo_exporter.log < /dev/null &
