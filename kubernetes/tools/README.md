This area contains tools for k8s infrastructure:
- `k8s_info` provides useful information such as image version, pod node
  assignment, etc., for given namespace(s) or entire cluster. To build it use
  the following command on lxplus:
```
# build the executable
go build -o k8s_info k8s_info.go

# use the executable
k8s_info -help
Usage of ../tools/k8s_info:
  -n string
        k8s namespace
  -pattern string
        pod name pattern to show
  -pod string
        k8s pod
  -verbose int
        verbosity level

# list pods in das namespace
k8s_info -n das

# list pods in dbs namespace matching pattern
k8s_info -n dbs -pattern dbs2go
```
