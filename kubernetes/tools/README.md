This area contains tools for k8s infrastructure:
- `k8s_info` provides useful information such as image version, pod node
  assignment, etc., for given namespace(s) or entire cluster. To build it use
  the following command on lxplus:
```
# build the executable
go build k8s_info.go

# use the executable
k8s_info -help
Usage of ../tools/k8s_info:
  -ns string
        k8s namespace
  -pod string
        k8s pod
  -verbose int
        verbosity level

# list pods in das namespace
k8s_info -ns das
```
