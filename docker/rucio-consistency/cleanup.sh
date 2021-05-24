#! /bin/sh

find /var/cache/consistency-dump -mtime +45 -exec rm {} \;
