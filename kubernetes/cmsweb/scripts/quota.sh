#!/bin/bash
if [ $# -ne 1 ]; then
     echo "Usage: ./quota.sh \"PROJECT NAME\" "
     exit 1;
fi

export OS_PROJECT_NAME=$1

cpus=`openstack quota show | grep core | awk '{print $4}'`
ram=`openstack quota show | grep ram | awk '{print $4}'`
instances=`openstack quota show | grep instances | awk '{print $4}'`

volumes=`openstack quota show | grep ' volumes ' | awk '{print $4}'`
volume_size=`openstack quota show | grep ' gigabytes ' | awk '{print $4}'`

volumes_used=`openstack volume list | tail -n +4 | grep -v + | wc -l`
volume_size_used=`openstack volume list | tail -n +4 | grep -v + | awk '{ SUM += $8} END { print SUM }'`
instances_used=`openstack server list | grep -v + | grep -v Flavor | wc -l`

shares=`manila quota-show | grep ' shares ' | awk '{print $4}'`
shares_used=`manila list | grep -v + | tail -n +2 | wc -l`
shares_size=`manila quota-show | grep ' gigabytes ' | awk '{print $4}'`
shares_size_used=`manila list | grep -v + | tail -n +2 | awk '{ SUM += $6} END { print SUM }'`

openstack server list | awk '{print $12}' | sort | uniq -c | grep -v Flavor | tail -n +2 | awk '{print $1","$2}' > server.list

cpus_used=0
ram_used=0


input="server.list"
while IFS= read -r line
do
 
  number_of_servers=`echo "$line" | cut -d ',' -f1`
  server_flavor=`echo "$line" | cut -d ',' -f2`

  cpus_used=$((cpus_used+`openstack flavor list | grep $server_flavor | awk '{print $12}'`*number_of_servers))
  ram_used=$((ram_used+`openstack flavor list | grep $server_flavor | awk '{print $6}'`*number_of_servers))


done < "$input"

rm server.list

ram=$((ram/1024))
ram_used=$((ram_used/1024))


echo "Total CPUs in Quota: $cpus ,  Total CPUs Used: $cpus_used"
echo "Total RAM in Quota: $ram ,  Total Ram Used: $ram_used"
echo "Total Instances: $instances , Total Instances Used: $instances_used"
echo "Total Volumes in Quota: $volumes , Volumes Used: $volumes_used"
echo "Total Volume Size in Quota: $volume_size , Total Volume Size Used: $volume_size_used"

echo "Total Quota of CephFS Shares: $shares , Total Shares Used: $shares_used"
echo "Total Quota of CephFS Shares Size: $shares_size , Total Shares Size Used: $shares_size_used"

echo "#####################  Output in JSON  ##################"

JSON_STRING=$( jq -n \
                  --arg cpus "$cpus" \
                  --arg cpus_used "$cpus_used" \
                  --arg ram "$ram" \
                  --arg ram_used "$ram_used" \
                  --arg instances "$instances" \
                  --arg instances_used "$instances_used" \
                  --arg volumes "$volumes" \
                  --arg volumes_used "$volumes_used" \
                  --arg volume_size "$volume_size" \
                  --arg volume_size_used "$volume_size_used" \
                  --arg shares "$shares" \
                  --arg shares_used "$shares_used" \
                  --arg shares_size "$shares_size" \
                  --arg shares_size_used "$shares_size_used" \
                  '{total_cpus: $cpus, cpus_used: $cpus_used, total_ram: $ram, ram_used: $ram_used, total_instances: $instances, instances_used: $instances_used, total_volume: $volumes, volumes_used: $volumes_used, total_volume_size: $volume_size, total_volume_size_used: $volume_size_used, total_shares: $shares, shares_used: $shares_used, shares_size: $shares_size, shares_size_used: $shares_size_used,}' )

echo $JSON_STRING
