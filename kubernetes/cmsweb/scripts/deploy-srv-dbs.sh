#!/bin/bash

# Define the target namespace in the new cluster
target_namespace="dbs"

# Mapping of service names to their full image tags
declare -A service_image_tags=(
    ["check-metric"]="registry.cern.ch/cmsweb/check-metric:20220404-stable"
    ["dbs2go-global-m"]="registry.cern.ch/cmsweb/dbs2go:v00.06.42-stable"
    ["dbs2go-global-migration"]="registry.cern.ch/cmsweb/dbs2go:v00.06.42-stable"
    ["dbs2go-global-r"]="registry.cern.ch/cmsweb/dbs2go:v00.06.42-stable"
    ["dbs2go-global-w"]="registry.cern.ch/cmsweb/dbs2go:v00.06.43-stable"
    ["dbs2go-phys03-m"]="registry.cern.ch/cmsweb/dbs2go:v00.06.42-stable"
    ["dbs2go-phys03-migration"]="registry.cern.ch/cmsweb/dbs2go:v00.06.42-stable"
    ["dbs2go-phys03-r"]="registry.cern.ch/cmsweb/dbs2go:v00.06.42-stable"
    ["dbs2go-phys03-w"]="registry.cern.ch/cmsweb/dbs2go:v00.06.43-stable"
)

# Loop through the service names and their full image tags
for service in "${!service_image_tags[@]}"; do
    full_image_tag="${service_image_tags[$service]}"
    tag_part="${full_image_tag##*:}"
    echo "Deploying $service with image tag $tag_part to $target_namespace namespace"
    ./deploy-srv.sh "$service" "$tag_part"
done

