#!/bin/bash

echo "Executing initialize-mongo-rs.sh"

mongo --eval "mongodb = ['$NODE_HOSTNAME_ONE:32001', '$NODE_HOSTNAME_TWO:32002', '$NODE_HOSTNAME_THREE:32003'], rsname = '$RS_NAME'" --shell << EOL
cfg = {
        _id: rsname,
        members:
            [
                {_id : 0, host : mongodb[0], priority : 1},
                {_id : 1, host : mongodb[1], priority : 0.9},
                {_id : 2, host : mongodb[2], priority : 0.5}
            ]
        }
rs.initiate(cfg)
EOL

/root/initialize-users.sh &
