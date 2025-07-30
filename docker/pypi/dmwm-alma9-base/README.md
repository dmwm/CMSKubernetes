# DMWM-alma9-base Image

This image may be used for dmwm services as a base image.

## Building
```
docker buildx build -t registry.cern.ch/cmsweb/dmwm-base:<preferred-tag-here> .
```

## Certificates
/etc/grid-security/certificates and /etc/grid-security/vomsdir need to be mounted
