## Debugging issues with the certificates.

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
## List of components that are related to DMWM services
#### Networking
Calico Node and CoreDNS are specific components within the Kubernetes ecosystem, each serving distinct functions:

1. **Calico Node**:

   - **Function**: Calico Node is a component that runs on every node within a Kubernetes cluster. Its primary function is to implement networking and network security policies for pods running on that node.

   - **Key Responsibilities**:
     - **Network Connectivity**: Calico Node assigns a unique IP address to each pod on the node, enabling network connectivity for the pods.
     - **Network Policy Enforcement**: It enforces network policies defined in Kubernetes that control pod-to-pod communication, allowing or denying traffic based on policy rules.
     - **Routing**: Calico Node uses the Border Gateway Protocol (BGP) to establish and manage routing between nodes, ensuring that pods can communicate across the cluster.
     - **IPAM (IP Address Management)**: It manages the allocation and release of IP addresses for pods, preventing IP address conflicts.

   - **Location and Debugging**:  It runs as a deamonset in the kube-system namespace. 
       ```
       [apervaiz@lxplus810 ~]$ kubectl -n kube-system get pods -l k8s-app=calico-node
         NAME                READY   STATUS    RESTARTS   AGE
         calico-node-4hn44   1/1     Running   0          20d
         calico-node-5tqfn   1/1     Running   0          20d
         calico-node-5x92h   1/1     Running   0          20d
         calico-node-9wtsj   1/1     Running   0          20d
         calico-node-bk4rn   1/1     Running   0          20d
         calico-node-cbqz6   1/1     Running   0          20d
         calico-node-dwj8b   1/1     Running   0          20d
         calico-node-hdpvh   1/1     Running   0          20d
         calico-node-jz4hm   1/1     Running   0          20d
         calico-node-ldhhp   1/1     Running   0          20d
         calico-node-n5dd4   1/1     Running   0          20d
         calico-node-qlrrc   1/1     Running   0          20d
         calico-node-svlhr   1/1     Running   0          20d
         calico-node-v4ltv   1/1     Running   0          20d
         calico-node-zwrxb   1/1     Running   0          20d

       ```
       Usually, restarting the deamonset fixes the issue. The most common error that occurs when there is an issue with calico is `CNI plugin: error getting ClusterInformation: connection is unauthorized: Unauthorized`

3. **CoreDNS**:

   - **Function**: CoreDNS is the DNS server used for DNS resolution and service discovery within a Kubernetes cluster. It resolves DNS queries made by pods and services to discover other services and communicate with them.

   - **Key Responsibilities**:
     - **DNS Resolution**: CoreDNS resolves domain names, such as service names, to their corresponding IP addresses within the cluster.
     - **Service Discovery**: It provides DNS records for Kubernetes services, enabling applications to locate and communicate with other services using DNS names.
     - **DNS-Based Service Routing**: CoreDNS translates DNS queries into IP addresses, allowing traffic to be routed to the appropriate services based on their DNS names.
     - **Plugin Extensibility**: CoreDNS is highly extensible through plugins, which allows customizing DNS functionality to suit specific needs.
     - **Caching**: CoreDNS can cache DNS responses to improve performance and reduce the load on DNS servers.
   - **Location and Debugging**: It runs as a deployment in the kube-system namespace.
     ```
     [apervaiz@lxplus810 ~]$ kubectl -n kube-system get pods -l k8s-app=kube-dns
      NAME                       READY   STATUS    RESTARTS        AGE
      coredns-6d78487f9b-xjvcr   1/1     Running   0               21d
      coredns-6d78487f9b-zgwpc   1/1     Running   0               21d

     ```
      Usually, restarting the deployment fixes the issue. Sometimes, you have to ensure that you are running the latest configuration. The configuration changes are made by       the CERN IT. The most common type of error is `FailedCreatePodSandBox        Failed to create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container.`

In summary, Calico Node is responsible for managing networking and network security policies at the node level, ensuring connectivity and security for pods, while CoreDNS is the DNS server responsible for resolving domain names and enabling service discovery within the Kubernetes cluster. Together, they contribute to the effective functioning of a Kubernetes environment.


#### Robot certificates/ Cron-proxy
For cmsweb operations, we need to have a valid proxy on our backends. Originally, we used operator proxy and uploaded it to myproxy server. The
cmsweb ProxySeed and ProxyRenew scripts were used.

Now, we can obtain CERN service account and apply for a Robot certificate. Once received, we obtain robotcert.pem/robotkey.pem files and we need to
register them in [LCG VOMS server](https://lcg-voms2.cern.ch:8443).  Then, we'll mount them in secrets volume in the k8s cluster and use them for acquiring proxies
within k8s pods, see [proxy.sh](https://github.com/dmwm/CMSKubernetes/blob/master/docker/proxy/proxy.sh) file for example. It runs as a cronjob, named `cron-proxy.`


