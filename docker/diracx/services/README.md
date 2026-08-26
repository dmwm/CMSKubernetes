How to test new image:

```
docker run --rm diracx-services-htcondor:v0.3.0 python -c "import htcondor2; print('HTCondor version:', htcondor2.version())"
HTCondor version: $CondorVersion: 25.13.2 2026-08-20 BuildID: UW_Python_Wheel_Build RC $
```
