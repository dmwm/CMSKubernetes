# Simple stuff to put in an interactive shell which can run in the k8s cluster
#
# Licensed under the Apache License, Version 2.0 (the "License");
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Authors:
# - Eric Vaandering, <ewv@fnal.gov>, 2018

FROM centos:7

RUN yum install -y nc bind-utils nano && \
    yum clean all && \
    rm -rf /var/cache/yum

