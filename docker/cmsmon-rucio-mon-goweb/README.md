## cmsmon-rucio-mon-goweb

Notes:
- Built by github wf
- `gcr.io/distroless/static` gives: standard_init_linux.go:219: exec user process caused: no such file or directory.
  - it seems go executable requires `libc` somewhere
  - Reference for `libc` in go: https://github.com/GoogleContainerTools/distroless/blob/main/base/README.md


#### References
- docker/dbs2go/Dockerfile
