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

In summary, calico is responsible for managing networking and network security policies at the node level, ensuring connectivity and security for pods, while CoreDNS is the DNS server responsible for resolving domain names and enabling service discovery within the Kubernetes cluster. Together, they contribute to the effective functioning of a Kubernetes environment.


#### Robot certificates/ Cron-proxy
For cmsweb operations, we need to have a valid proxy on our backends. Originally, we used operator proxy and uploaded it to myproxy server. The
cmsweb ProxySeed and ProxyRenew scripts were used.

Now, we can obtain CERN service account and apply for a Robot certificate. Once received, we obtain robotcert.pem/robotkey.pem files and we need to
register them in [LCG VOMS server](https://lcg-voms2.cern.ch:8443).  Then, we'll mount them in secrets volume in the k8s cluster and use them for acquiring proxies
within k8s pods, see [proxy.sh](https://github.com/dmwm/CMSKubernetes/blob/master/docker/proxy/proxy.sh) file for example. It runs as a cronjob, named `cron-proxy.`

#### Frontends

When you want to add a new service to be hosted under CMSWeb, you have to take the following steps:
  - The [deployment/frontend](https://github.com/dmwm/deployment/tree/master/frontend)
repository contains SSL and NOSSL redirect rules for individual services or namespaces. They are labeled as app\_\<service-name\>\_ssl.conf and app\_\<service-name\>\_nossl.conf. You have to insert redirect rules there.
  - Then, we need to insert rules in backends-k8s-prod.txt and backends-k8s-preprod.txt to let the frontends know where we would like our requests to be redirected. For K8s, you just need to supply a single `backends.txt` file with proper rules. This file is present in the [services_config/-/tree/cmsweb/frontend-ds](https://gitlab.cern.ch/cmsweb-k8s/services_config/-/tree/cmsweb/frontend-ds?ref_type=heads) branch for the production cluster, for preproduction cluster, it is present in the [services_config/-/tree/preprod/frontend-ds](https://gitlab.cern.ch/cmsweb-k8s/services_config/-/tree/preprod/frontend-ds?ref_type=heads), and for test cluster, it is present in [services_config/-/tree/test/frontend-ds](https://gitlab.cern.ch/cmsweb-k8s/services_config/-/tree/test/frontend-ds?ref_type=heads).

- How do you check if your changes for a particular service are there?
  - Exec into the frontend pod:
    ```
    kubectl exec -it frontend-pod -n auth
    ```
  - Then, check if the rules exist for the service, let's say, MS-PileUP, in the following locations:
    ```
        [_frontend@cmsweb-testbed-v1-22-zone-a-whjk2m547jvl-node-0 data]$ cat srv/state/frontend/server.conf | grep ms-pileup
      RewriteRule ^(/ms-pileup-tasks(/.*)?)$ /auth/verify${escape:$1} [QSA,PT,E=AUTH_SPEC:cert]
      RewriteRule ^/auth/complete(/ms-pileup-tasks(/.*)?)$ http://%{ENV:BACKEND}:8361${escape:$1} [QSA,P,L,NE]
      RewriteRule ^(/ms-pileup(/.*)?)$ /auth/verify${escape:$1} [QSA,PT,E=AUTH_SPEC:cert]
      RewriteRule ^/auth/complete(/ms-pileup(/.*)?)$ http://%{ENV:BACKEND}:8241${escape:$1} [QSA,P,L,NE]
      RewriteRule ^(/ms-pileup-tasks(/.*)?)$ https://%{SERVER_NAME}${escape:$1}%{env:CMS_QUERY} [R=301,NE,L]
      RewriteRule ^(/ms-pileup(/.*)?)$ https://%{SERVER_NAME}${escape:$1}%{env:CMS_QUERY} [R=301,NE,L]
    ```
    AND
    ```
        [_frontend@cmsweb-testbed-v1-22-zone-a-whjk2m547jvl-node-0 data]$ cat srv/current/config/frontend/backends.txt | grep ms-pileup
    ^/auth/complete/ms-pileup(?:/|$) ms-pileup.dmwm.svc.cluster.local
    ```
  - If they don't exist in backends.txt, update the secrets by applying the services_config files mentioned above, and restart the frontend daemonset.
  - If they don't exist in the server.conf or `srv/current/config/frontend/app\_\<service-name\>\_ssl/nossl.conf` files, and you are sure your changes were incorporate, then maybe your cluster is running an older version of the frontend service.

## Health/Load of the cluster

1. **Get Cluster Information**:
   - To get general information about your cluster, including its version and nodes, use: `kubectl cluster-info`.

2. **Check Node Status**:
   - To view the status of your cluster nodes and their resource utilization, you can use: `kubectl get nodes`.

3. **View Pod Status**:
   - To check the status of pods running in your cluster: `kubectl get pods -n <namespace>`.

4. **Get Resource Usage**:
   - Use `kubectl top` to check resource usage for nodes or pods. For example, to view CPU and memory usage for pods: `kubectl top pods -n <namespace>`.
   - To view node resource usage: `kubectl top nodes`.

5. **Check Cluster Events**:
   - To see recent cluster events, run: `kubectl get events`.

6. **Examine Logs**:
   - View logs of a pod for troubleshooting or performance analysis: `kubectl logs <pod-name> -n <namespace>`.

7. **List Deployments**:
   - List all deployments in a namespace: `kubectl get deployments -n <namespace>`.

8. **Scale Deployments**:
   - Scale a deployment up or down using `kubectl scale`. For example, to scale a deployment to 3 replicas: `kubectl scale deployment <deployment-name> --replicas=3 -n <namespace>`.

9. **Resource Requests and Limits**:
   - Check the resource requests and limits of pods with: `kubectl describe pod <pod-name> -n <namespace>`. This helps you understand resource allocation.

10. **Pod Restart Count**:
    - To see how many times a pod has been restarted, use: `kubectl get pods <pod-name> -n <namespace> -o=jsonpath='{.status.containerStatuses[0].restartCount}'`.

11. **Rolling Restart**:
    - Perform a rolling restart of a deployment: `kubectl rollout restart deployment/<deployment-name> -n <namespace>`.

12. **Attach to Running Pod**:
    - Attach to a running pod for interactive troubleshooting: `kubectl exec -it <pod-name> -n <namespace> -- /bin/sh`.

13. **Horizontal Pod Autoscaling**:
    - To check the status of Horizontal Pod Autoscalers (HPA), use: `kubectl get hpa -n <namespace>`.

14. **Check API Resources**:
    - Get a list of available API resources with: `kubectl api-resources`.

15. **Check Component Status**:
     - To view the status of core Kubernetes components, use: `kubectl get componentstatus`.

16. **API Server Health**:
     - Check the health of the Kubernetes API server: `kubectl get --raw /healthz`.
     - To get more detailed information about the API server, use: `kubectl describe componentstatuses kube-apiserver`.

17. **Kubelet Health**:
     - Verify the health of Kubelet on each node: `kubectl describe nodes`.

18. **Control Plane Components**:
     - Examine the status of control plane components by running: `kubectl get pods -n kube-system`.

19. **Check Cluster DNS**:
     - Confirm the health of the cluster DNS by running: `kubectl get pods -n kube-system -l k8s-app=kube-dns`.

20. **Storage Provisioners**:
     - To check the status of storage provisioners, run: `kubectl get storageclass`.

21. **Persistent Volume Claims (PVCs)**:
     - Verify the status of PVCs in a particular namespace: `kubectl get pvc -n <namespace>`.

22. **Cluster Version**:
    - To check the version of the Kubernetes cluster, you can use: `kubectl version`.


