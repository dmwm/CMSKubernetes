#!/bin/bash

source /sec/cmsweb-openrc.sh
openstack coe cluster list
openstack volume snapshot create --volume $VOLUME_NAME $SNAPSHOT_NAME --force  