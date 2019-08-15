### cmsweb kubernetes
This directory contains all necessary files to deploy cmsweb cluster
to kubernetes. The structure is the following
- [crons](crons) directory contains all cronjob configuration files
- [dev](dev) directory contains development files
- [docs](docs) provides all documentation files
- [ingress](ingress) directory contains ingress controller files
- [legacy](legacy) directory contains legacy deployment files
- [monitoring](monitoring) directory contains all cmsweb monitoring files
- [old](old) directory contains old code base, e.g. how to deploy ingress nginx
  controller
- [scripts](scripts) area contains all scripts
- [services](services) area contains configuration files for cmsweb services

To learn about cmsweb k8s architecture please read
[architecture](docs/architecture.md) document.

To deploy cmsweb on kubernetes please follow these steps:
- [cluster creation](docs/cluster.md)
- [general deployment](docs/deployment.md)
- [cmsweb deployment](docs/cmsweb-deployment.md)
- [nginx](docs/nginx.md)
- [autoscaling](docs/autoscaling.md)
- [storage](docs/storage.md)
- [troubleshooting](docs/troubleshooting.md)
- [references](docs/references.md)
