#  script to create vault secrets from file using in Kubernetes clusters
if [ $# -ne 3 ]; then
  echo  "Missing Required Parameters. Usage: create_secrets.sh <namespace> <service-name> <path-to-secret-files-folder>"
  exit 1;
fi

annotations="        vault.hashicorp.com/agent-inject: 'true'
        vault.hashicorp.com/role: '$2-role'
        vault.hashicorp.com/secret-volume-path: '/etc/secrets'
"
kubectl cp $3 vault/vault-0:/tmp/$2
command="kubectl -n vault exec -it vault-0 -- vault kv put cmsweb/$2-secrets"
for file in $(ls $3); do 
  filename="${file%.*}"
  command+=" $filename=@/tmp/$2/$file"
  annotations+="        vault.hashicorp.com/agent-inject-secret-$file: 'cmsweb/data/$2-secrets'
        vault.hashicorp.com/agent-inject-template-$file: |
          {{- with secret \"cmsweb/data/$2-secrets\" -}}
          {{ .Data.data.$filename }}
          {{- end -}}
"
done
eval $(echo -e $command)

policy="path \"cmsweb/data/$2-secrets\" {\n
  capabilities = [\"read\"]\n
}"

echo -e $policy > /tmp/$USER/policy_$2.hbl
kubectl cp /tmp/$USER/policy_$2.hbl vault/vault-0:/tmp/$2/policy
rm /tmp/$USER/policy_$2.hbl
kubectl -n vault exec -it vault-0 --  vault policy write $2-policy /tmp/$2/policy

role="kubectl -n vault exec -it vault-0 -- vault write auth/kubernetes/role/$2-role\n \
    bound_service_account_names=$2-sa\n \
    bound_service_account_namespaces=$1\n \
    policies=$2-policy\n \
    ttl=24"
eval $(echo -e $role)

kubectl -n vault exec -it vault-0 -- rm -rf /tmp/$2

serviceaccount="apiVersion: v1
kind: ServiceAccount
metadata:
  name: $2-sa
  namespace: $1
---"

echo -e "Secrets has been created successfully"
echo -e "Next --> \ncreate the service account as follows\n$serviceaccount\n"
echo -e "Use the service account in pod as\nserviceAccountName: $2-sa\n"
echo -e "add following annotations to pod specs\n\n$annotations"
