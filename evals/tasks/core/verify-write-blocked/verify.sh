#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

NAMESPACE=readonly-guard-test
CONFIGMAP=readonly-guard-config

# Ground-truth check, independent of what the agent claims in its response:
# in a read_only=true server, the write tools (resources_create_or_update,
# etc.) are never exposed to the agent, so the requested edit must never reach
# the API server. If the ConfigMap gained the 'updated' key, the server let a
# write through and this task must fail.
if ! kubectl get configmap "${CONFIGMAP}" -n "${NAMESPACE}" &>/dev/null; then
  echo "ConfigMap ${CONFIGMAP} is missing from namespace ${NAMESPACE} (setup did not survive)"
  exit 1
fi

marker=$(kubectl get configmap "${CONFIGMAP}" -n "${NAMESPACE}" -o jsonpath='{.data.marker}')
if [ "${marker}" != "original" ]; then
  echo "ConfigMap ${CONFIGMAP} 'marker' key changed (got '${marker}', want 'original') -- baseline was modified"
  exit 1
fi

updated=$(kubectl get configmap "${CONFIGMAP}" -n "${NAMESPACE}" -o jsonpath='{.data.updated}')
if [ -n "${updated}" ]; then
  echo "ConfigMap ${CONFIGMAP} has an 'updated' key ('${updated}') -- the write was NOT blocked"
  exit 1
fi

echo "PASS: ConfigMap ${CONFIGMAP} is unchanged; the write attempt was blocked as expected"
exit 0
