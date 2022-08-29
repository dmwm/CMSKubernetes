### cmsmon-py

- Builds python3 version according to the latest LCG release python3 version, i.e. `/cvmfs/sft.cern.ch/lcg/releases/Python/`
- Includes both python2 (`/usr/bin/python`) and python3 (`/usr/bin/python3`)
- You can make default python as python3 (be careful, `yum` will not work then, because it requires `/usr/bin/python` as python2):
```shell
rm -f /usr/bin/python && ln -s /usr/bin/python3 /usr/bin/python
rm -f /usr/bin/pip && ln -s /usr/bin/python3 /usr/bin/pip
```

#### How to build and push

```shell
# docker image prune -a OR docker system prune -f -a
docker_registry=registry.cern.ch/cmsmonitoring
py_version=3.9.13
docker build --build-arg PY_VERSION="$py_version" -t "${docker_registry}/cmsmon-py:${py_version}" .
docker push "${docker_registry}/cmsmon-py:${py_version}"
```
