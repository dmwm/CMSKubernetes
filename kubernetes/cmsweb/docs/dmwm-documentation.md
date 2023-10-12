### Debugging issues with the certificates.

- How do I change p12 to pem?
```
openssl pkcs12 -in path.p12 -out newfile.crt.pem -clcerts -nokeys
openssl pkcs12 -in path.p12 -out newfile.key.pem -nocerts -nodes
```
- How do I check the end dates for the certificates?
```
openssl x509 -enddate -noout -in file.pem
```
- How do I check the subjects of the certificate?
```
openssl x509 -noout -subject -in file.pem

```
- Who is in charge of updating the certificates?
```
The CMSWeb Operator/CMS-HTTP-GROUP.
```
- Where are the service certificates for the dmwm services located?

  - Exec into the pod.
  - cd /data/srv/current/auth/reqmgr2ms/
    ```
    _reqmgr2ms@ms-transferor-66598fc95b-6xjs7:/data$ ls -lrt srv/current/auth/reqmgr2ms/
    total 8
    -r--------. 1 _reqmgr2ms _reqmgr2ms 1828 Sep 29 14:06 dmwm-service-key.pem
    -rw-r--r--. 1 _reqmgr2ms _reqmgr2ms 3513 Sep 29 14:06 dmwm-service-cert.pem
    
    ```
- How do I check if the host certificates are expired?
```
[apervaiz@lxplus812 ~]$ echo | openssl s_client -connect <cluster-url>:443 2>/dev/null | openssl x509 -noout -dates
notBefore=Feb 28 02:56:51 2023 GMT
notAfter=Apr  3 02:56:51 2024 GMT
```
