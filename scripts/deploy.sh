#!/usr/bin/env bash
# Convenience wrapper: render .env -> kustomize inputs, then apply k8s/.
# Equivalent to running scripts/gen-kustomize-inputs.sh followed by
#   kubectl --kubeconfig endeavour.yaml apply -k k8s
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

KUBECONFIG_FILE="${KUBECONFIG:-$PROJECT_DIR/endeavour.yaml}"
if [ ! -f "$KUBECONFIG_FILE" ]; then
  echo "Error: kubeconfig $KUBECONFIG_FILE not found." >&2
  exit 1
fi

"$SCRIPT_DIR/gen-kustomize-inputs.sh"

echo "Applying k8s/ ..."
kubectl --kubeconfig "$KUBECONFIG_FILE" apply -k "$PROJECT_DIR/k8s"

echo "Waiting for rollout..."
kubectl --kubeconfig "$KUBECONFIG_FILE" rollout status -n vtlib deployment/primomcp

echo "Deployment complete."
