## Testing CMSWEB Services using Hey Tool
We consider hey tool to test load of CMSWEB services. [Hey](https://github.com/rakyll/hey)  is a tiny program that sends some load to a web application. 

The [bench_k8s.sh](https://github.com/dmwm/CMSKubernetes/blob/master/kubernetes/cmsweb/scripts/bench_k8s.sh) is available to test the load of CMSWEB services. 

### Usage of Bench Script 

The bench script accepts two parameters. First parameter should be the name of the cluster and second parameter should be the total number of runs for which average is to be calculated. 

For example:

- `./bench_k8s.sh https://cmsweb-testbed.cern.ch 10`

The script will display the result of all CMSWEB services in terms of requests/second. 

As it can be noticed in the script that we used [`-n 10 -c 5`](https://github.com/dmwm/CMSKubernetes/blob/master/kubernetes/cmsweb/scripts/bench_k8s.sh#L27) where `-n` is the number of requests to run and `-c` is the number of workers to run concurrently. Total number of requests cannot be smaller than the concurrency level. Developers can adjust these values according to their convenience. 


