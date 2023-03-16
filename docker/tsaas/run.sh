#!/bin/bash
torchserve --start --ncs --model-store model_store
for i in {0..10..1}
do
    echo "Waiting for torserve to start ..."
    ls
    sleep 1
    if [ -d logs ]; then
        break
    fi
done
tail -f logs/access_log.log
