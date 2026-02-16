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

if [ -z "${CONTAINER_REGISTRY:-}" ]; then
  echo "Error: CONTAINER_REGISTRY is not set in $ENV_FILE" >&2
  exit 1
fi

IMAGE="$CONTAINER_REGISTRY/primomcp:latest"

echo "Building $IMAGE..."
docker build -t "$IMAGE" "$PROJECT_DIR"

echo "Pushing $IMAGE..."
docker push "$IMAGE"

echo "Done. Image pushed to $IMAGE"
