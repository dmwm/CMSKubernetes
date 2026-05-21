# Vault resources for monitoring

This folder contains the manifests for the Kubernetes objects needed by the Vault Secrets Operator to reach the CERN Vault instances and authenticate on behalf of monitoring workloads.

The manifests are meant to be applied to the same cluster where the operator runs.

This documentation and setup refers specifically to the deployment of the VSO integration of Vault into Kubernetes. For a comprehensive comparison between the different methods and their benefits, see [the official Vault@CERN documentation](https://vault.docs.cern.ch/docs/integration/comparison/), and for documentation about how to set up each of the different approaches for integration, [this other section of the documentation](https://vault.docs.cern.ch/docs/integration/).

If you have any questions about setting up Vault within your infrastructure after going through this documentation (and the official one linked above), feel free to contact us for help, or to send a message in the official [Vault Mattermost channel](https://mattermost.web.cern.ch/it-dep/channels/vault).

## Prerequisites

- Access to the Vault cluster (`woger-vault.cern.ch` for test environment or `vault-it.cern.ch` prod). You can get it by [creating a SNOW ticket to CERN IT Vault team](https://cern.service-now.com/service-portal?id=sc_cat_item&name=Configuration-Management-Incident&se=Configuration-Management) (it says the ticket is for reporting a Configuration Management issue but they do not have a specific SNOW space at the moment).
- Keep in mind that everything deployed in this folder is done in a blank namespace specifically created for Vault resources. This is not mandatory but it is still highly recommended. The namespace used in this documenation and in the manifest is `vault-secrets-operator`.
- Proper CA Certificate bundle for the Vault auth resource setup. In this case we have deployed a secret using the following command:

```bash
kubectl create secret generic vault-ca-cert --from-file=ca.crt=./etc/pki/tls/certs/ca-bundle.crt -n vault-secrets-operator
```

## Customise the manifests

1. Update `vault-connection.yaml`:
   - Set `spec.address` to the Vault endpoint you want to target.
   - Adjust `spec.caCertSecretRef` if the CA secret name differs.
2. Update `vault-auth.yaml`:
   - Update the `mount` field with the path to the secret engine provided for you by the Vault team.
   - Make sure that `role`, and `allowedNamespaces` match the Vault auth method and Kubernetes namespaces you intend to allow.
3. Review `vault-service-account.yaml`:
   - Ensure the `namespace` value align with where the operator runs.

## Resource purpose and flow

### `vault-service-account.yaml`

- **ServiceAccount** `vault-auth` lets the operator authenticate to Kubernetes and receive tokens scoped specifically for Vault access.

- **ClusterRole** `vault-token-reviewer` grants permission to request service account tokens and inspect pods/secrets, which Vault needs to validate Kubernetes JWTs.

- **ClusterRoleBinding** ties the ServiceAccount to the ClusterRole so the operator can perform token reviews.

### `vault-connection.yaml`

- Defines how the operator reaches Vault (endpoint URL, TLS, CA bundle). Without this object the operator cannot establish a session with Vault.

### `vault-auth.yaml`

- Points at the connection, declares the `kubernetes` auth method, and references the ServiceAccount/role. This resource links Kubernetes identities to Vault roles and specifies which namespaces may use the auth configuration.

Together these manifests ensure the operator can present a Kubernetes service account token, Vault can validate it via the token reviewer permissions, and the operator can fetch secrets from the configured Vault mount.

## Deploy the resources

```bash
kubectl apply -f /root/projects/CMSKubernetes/kubernetes/monitoring/vault/vault-service-account.yaml
kubectl apply -f /root/projects/CMSKubernetes/kubernetes/monitoring/vault/vault-connection.yaml
kubectl apply -f /root/projects/CMSKubernetes/kubernetes/monitoring/vault/vault-auth.yaml
```

Apply them in that order so the ServiceAccount and RBAC exist before the Vault
connection and auth references.

## Verification

- Confirm the ServiceAccount secret was created:

  ```bash
  kubectl -n vault-secrets-operator get sa vault-auth -o yaml
  ```

- Check the operator logs to ensure it establishes the connection and auth:

  ```bash
  kubectl -n vault-secrets-operator logs deploy/vault-secrets-operator
  ```
