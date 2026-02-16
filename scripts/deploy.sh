#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load .env from project root
ENV_FILE="$PROJECT_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: $ENV_FILE not found. Copy .env.sample to .env and fill in values." >&2
  exit 1
fi
set -a
source "$ENV_FILE"
set +a

# Validate required variables
for var in NAMESPACE PRIMO_API_KEY INGRESS_HOST CONTAINER_REGISTRY IMAGE_PULL_SECRET; do
  if [ -z "${!var:-}" ]; then
    echo "Error: $var is not set in $ENV_FILE" >&2
    exit 1
  fi
done

IMAGE="$CONTAINER_REGISTRY/primomcp:latest"

echo "Deploying to namespace $NAMESPACE..."

echo "Creating/updating primomcp-secret..."
kubectl create secret generic primomcp-secret \
  --namespace="$NAMESPACE" \
  --from-literal=PRIMO_API_KEY="$PRIMO_API_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Applying K8s manifests..."
kubectl apply -n "$NAMESPACE" -f "$PROJECT_DIR/k8s/configmap.yaml"
kubectl apply -n "$NAMESPACE" -f "$PROJECT_DIR/k8s/service.yaml"

sed -e "s|__IMAGE__|$IMAGE|" -e "s|__IMAGE_PULL_SECRET__|$IMAGE_PULL_SECRET|" "$PROJECT_DIR/k8s/deployment.yaml" \
  | kubectl apply -n "$NAMESPACE" -f -

sed "s|__INGRESS_HOST__|$INGRESS_HOST|" "$PROJECT_DIR/k8s/ingress.yaml" \
  | kubectl apply -n "$NAMESPACE" -f -

echo "Waiting for rollout..."
kubectl rollout status -n "$NAMESPACE" deployment/primomcp

echo "Deployment complete."
