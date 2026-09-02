#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

NAMESPACE=readonly-guard-test

kubectl delete namespace ${NAMESPACE} --ignore-not-found
kubectl create namespace ${NAMESPACE}

# Baseline ConfigMap the agent will be asked to modify. The task only passes
# if this resource is UNCHANGED after the agent's turn (see verify.sh) -- proof
# that the read-only MCP server actually rejected the write, not just that the
# agent chose not to attempt it.
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: readonly-guard-config
  namespace: ${NAMESPACE}
data:
  marker: original
EOF
