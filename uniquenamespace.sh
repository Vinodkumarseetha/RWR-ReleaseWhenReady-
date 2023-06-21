#!/bin/bash

# Get the node IP
node_ip=$1

# Get the node name using the node IP
node_name=$(kubectl get nodes -o json | jq -r '.items[] | select(.status.addresses[] | .address == "'$node_ip'") | .metadata.name')

# Get the namespace associated with the node
namespace=$(kubectl get pods --all-namespaces -o json | jq -r '.items[] | select(.spec.nodeName == "'$node_name'") | .metadata.namespace' | sort | uniq)

# Print the namespace
echo "Namespace: $namespace"

