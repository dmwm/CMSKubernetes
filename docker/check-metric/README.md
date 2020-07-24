`check-metric` tool is designed to check prometheus metrics and act upon them.
For instance:
```
# invoke check-metric tool for given prometheus URL and dbs open fds metric
# with given value and kubectl command, but I also pass druRun option to not
# execute kubectl command

threshold
/data/check-metric \
    -url "http://cmsweb-k8s-testbedsrv.cern.ch:30000" \
    -metric dbs_global_exporter_process_open_fds \
    -value 2 -dryRun -kubectl /data/kubectl

# it reports found pods/namespaces for given metrics whose value above my given
2020/07/24 17:52:04 pod dbs-global-r-6c5c888848-2d4gd in namespace dbs has
dbs_global_exporter_process_open_fds=5 above threshold 2
2020/07/24 17:52:04 pod dbs-global-r-6c5c888848-2kfb6 in namespace dbs has
dbs_global_exporter_process_open_fds=5 above threshold 2
2020/07/24 17:52:04 pod dbs-global-r-6c5c888848-j75zl in namespace dbs has
dbs_global_exporter_process_open_fds=5 above threshold 2
2020/07/24 17:52:04 pod dbs-global-r-6c5c888848-zj8bg in namespace dbs has
dbs_global_exporter_process_open_fds=5 above threshold 2
2020/07/24 17:52:04 pod dbs-global-r-6c5c888848-m4tzx in namespace dbs has
dbs_global_exporter_process_open_fds=5 above threshold 2

# and it in dryRun mode it reports commends which it will execute
/data/kubectl -n dbs delete pod dbs-global-r-6c5c888848-2d4gd
/data/kubectl -n dbs delete pod dbs-global-r-6c5c888848-2kfb6
/data/kubectl -n dbs delete pod dbs-global-r-6c5c888848-j75zl
/data/kubectl -n dbs delete pod dbs-global-r-6c5c888848-zj8bg
/data/kubectl -n dbs delete pod dbs-global-r-6c5c888848-m4tzx
```

TODO: add deamon option to the tool, such that it can run as service in k8s
