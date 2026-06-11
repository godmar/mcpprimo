#!/usr/bin/env bash
# Render .env into the gitignored kustomize generator inputs under k8s/:
#   k8s/config.env        -> primomcp-config ConfigMap (non-secret app config)
#   k8s/secret.env        -> primomcp-secret Secret (PRIMO_API_KEY)
#   k8s/dockerconfigjson  -> registry-secret imagePullSecret (deploy token)
# Run this once, and again whenever .env changes. Then `kubectl apply -k k8s`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
K8S_DIR="$PROJECT_DIR/k8s"

ENV_FILE="$PROJECT_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: $ENV_FILE not found. Copy .env.sample to .env and fill in values." >&2
  exit 1
fi
set -a
source "$ENV_FILE"
set +a

for var in PRIMO_API_KEY PRIMO_BASE_URL PRIMO_VID PRIMO_TAB PRIMO_SCOPE \
           REGISTRY_SERVER REGISTRY_USERNAME REGISTRY_PASSWORD; do
  if [ -z "${!var:-}" ]; then
    echo "Error: $var is not set in $ENV_FILE" >&2
    exit 1
  fi
done

umask 077

# Non-secret application config
cat > "$K8S_DIR/config.env" <<EOF
PRIMO_BASE_URL=$PRIMO_BASE_URL
PRIMO_VID=$PRIMO_VID
PRIMO_TAB=$PRIMO_TAB
PRIMO_SCOPE=$PRIMO_SCOPE
PRIMO_INST=${PRIMO_INST:-}
PORT=${PORT:-3000}
EOF

# Secret application config
cat > "$K8S_DIR/secret.env" <<EOF
PRIMO_API_KEY=$PRIMO_API_KEY
EOF

# Registry deploy token as a dockerconfigjson
registry_auth="$(printf '%s:%s' "$REGISTRY_USERNAME" "$REGISTRY_PASSWORD" | base64 | tr -d '\n')"
cat > "$K8S_DIR/dockerconfigjson" <<EOF
{
  "auths": {
    "$REGISTRY_SERVER": {
      "username": "$REGISTRY_USERNAME",
      "password": "$REGISTRY_PASSWORD",
      "auth": "$registry_auth"
    }
  }
}
EOF

echo "Rendered k8s/config.env, k8s/secret.env, k8s/dockerconfigjson from .env (gitignored)."
