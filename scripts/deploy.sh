#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [ $# -lt 3 ]; then
  echo "Usage: $0 <NAMESPACE> <PRIMO_API_KEY> <INGRESS_HOST>" >&2
  echo "Example: $0 mcpprimo your-api-key mcpprimo.discovery.cs.vt.edu" >&2
  exit 1
fi

NAMESPACE="$1"
PRIMO_API_KEY="$2"
INGRESS_HOST="$3"

echo "Creating/updating primomcp-secret in namespace $NAMESPACE..."
kubectl create secret generic primomcp-secret \
  --namespace="$NAMESPACE" \
  --from-literal=PRIMO_API_KEY="$PRIMO_API_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Applying K8s manifests..."
kubectl apply -n "$NAMESPACE" -f "$PROJECT_DIR/k8s/configmap.yaml"
kubectl apply -n "$NAMESPACE" -f "$PROJECT_DIR/k8s/deployment.yaml"
kubectl apply -n "$NAMESPACE" -f "$PROJECT_DIR/k8s/service.yaml"

sed "s/__INGRESS_HOST__/$INGRESS_HOST/" "$PROJECT_DIR/k8s/ingress.yaml" \
  | kubectl apply -n "$NAMESPACE" -f -

echo "Waiting for rollout..."
kubectl rollout status -n "$NAMESPACE" deployment/primomcp

echo "Deployment complete."
