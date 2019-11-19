### CMS NATS
The [NATS](https://nats.io/) is secure and high performance open source
messaging system for distributed (cloud native) application written in Go.
It is similar to [Kafka](https://kafka.apache.org/), a
distributed streaming platform, written in Scala, Java.

### CMS NATS deployment to k8s
First we need to create a cluster where we'll deploy NATS servers.
This can be done using the following steps:
```
# login to lxplus-cloud
ssh lxplus-cloud

# create new cluster, you'll need to replace actual values, e.g.
# cloud, kubernetes-1.15.3-3 with appropriate ones suitable for your deployment
openstack coe cluster create --keypair cloud \
    --cluster-template kubernetes-1.15.3-3 \
    --flavor m2.medium --master-flavor m2.medium --node-count 2 nats-cluster
```

The deployment of CMS NATS to k8s cluster is trivial. Please follow
these steps:
```
# create a cluster
create_nats.sh <ssh key-pair> <cluster name>

# create clients-auth.json before deployment, e.g.
{
  "users": [
    {"username": "user1", "password": "password1", "permissions":{"publish":[">"]}},
    {"username": "user2", "password": "password2", "permissions":{"subscribe":[">"]}},
  ]
}

# deploy NATS server
deploy_nats.sh
```

That's it! If you want to connect `nats-top` tool to your running
cluster please use these commands:

```
kubectl run -i --rm --tty nats-box --image=synadia/nats-box:latest --restart=Never
nats-top -s nats-cluster-mgmt
```

### NATS clients
To use NATS system we need two types of clients. One is a publisher
and another is subscriber. For an example of Go based
tools please refer to
[go-nats-examples](https://github.com/nats-io/go-nats-examples)
repository. Here we'll only provide python publisher tools.

#### python2 NATS publisher
Here is an example of NATS publisher client
```
#!/usr/bin/env python

import os
import tornado.ioloop
import tornado.gen

from nats.io.client import Client as NATS

@tornado.gen.coroutine
def nats(server, subject, msg):
    nc = NATS()
    yield nc.connect(server)
    yield nc.publish(subject, msg)
    #nc.close()

def test():
    "Main function"
    server = 'nats://xxxx.cern.ch' # replace with your nats server name
    # a topic where we will publish messages
    subject = 'cms-wma'
    # a message we will publish. Here we use `___` as separator
    # and use key:value pairs for message content
    msg = 'exitCode:test___site:T1_Test___dataset:/a/b/c___task:test_task'
    tornado.ioloop.IOLoop.current().run_sync(lambda: nats(server, subject, msg))

if __name__ == '__main__':
    test()
```

#### python3 NATS publisher
```
#!/usr/bin/env python

from nats.aio.client import Client as NATS
import asyncio

async def nats(subject, msg, server=None):
    if not server:
        server = os.getenv('NATS_SERVER', 'nats://xxxx.cern.ch')
    nc = NATS()
    await nc.connect(server)
    await nc.publish(subject, msg)
    await nc.close()

def test():
    "Main function"
    subject = 'cms-test'
    msg = 'test from python3 asyncio'
    nats(subject, msg)

if __name__ == '__main__':
    test()
```

#### python publisher with external pub tool
If we want to use an external publisher tool we can use
python `subprocess` module for that, e.g.
```
#!/usr/bin/env python

# system modules
import os
import sys
import argparse
import subprocess

def nats(subject, msg, server=None):
    pub = os.getenv('NATS_PUB', '')
    if not pub:
        return
    if not server:
        server = os.getenv('NATS_SERVER', 'nats://xxxx.cern.ch')
    cmd = '{} -s {} {} "{}"'.format(pub, server, subject, msg)
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True, env=os.environ)
    proc.wait()
    return proc.returncode

def test():
    "Main function"
    subject = 'cms-test'
    msg = 'test from python'
    res = nats(subject, msg)
    print("return code", res)

if __name__ == '__main__':
    test()

```
