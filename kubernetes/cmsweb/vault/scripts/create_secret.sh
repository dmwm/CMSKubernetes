annotations="        vault.hashicorp.com/agent-inject: 'true'
        vault.hashicorp.com/role: '$1'
        vault.hashicorp.com/secret-volume-path: '/etc/secrets'
"
kubectl cp $2 vault/vault-0:/tmp/$1
command="kubectl -n vault exec -it vault-0 -- vault kv put cmsweb/$1"
for file in $(ls $2); do 
  filename="${file%.*}"
  command+=" $filename=@/tmp/$1/$file"
  annotations+="        vault.hashicorp.com/agent-inject-secret-$file: 'cmsweb/data/$1'
        vault.hashicorp.com/agent-inject-template-$file: |
          {{- with secret \"cmsweb/data/$1\" -}}
          {{ .Data.data.$filename }}
          {{- end -}}
"
done
eval $(echo -e $command)

policy="path \"cmsweb/data/$1\" {\n
  capabilities = [\"read\"]\n
}"

echo -e $policy > /tmp/$USER/policy_$1.hbl
kubectl cp /tmp/$USER/policy_$1.hbl vault/vault-0:/tmp/$1/policy
rm /tmp/$USER/policy_$1.hbl
kubectl -n vault exec -it vault-0 --  vault policy write $1 /tmp/$1/policy

role="kubectl -n vault exec -it vault-0 -- vault write auth/kubernetes/role/$1\n \
    bound_service_account_names=$1\n \
    bound_service_account_namespaces=default\n \
    policies=$1\n \
    ttl=24"
eval $(echo -e $role)

echo -e "$annotations"
kubectl -n vault exec -it vault-0 -- rm -rf /tmp/$1
