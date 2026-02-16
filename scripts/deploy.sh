#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <PRIMO_API_KEY>" >&2
  exit 1
fi

PRIMO_API_KEY="$1"

echo "Creating/updating primomcp-secret..."
kubectl create secret generic primomcp-secret \
  --from-literal=PRIMO_API_KEY="$PRIMO_API_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Applying K8s manifests..."
kubectl apply -f "$PROJECT_DIR/k8s/"

echo "Waiting for rollout..."
kubectl rollout status deployment/primomcp

echo "Deployment complete."
