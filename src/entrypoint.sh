#!/usr/bin/env bash
set -e

# Prefer Pterodactyl's SERVER_PORT, otherwise fall back to 5000
: "${SERVER_PORT:=5000}"

# If REGISTRY_HTTP_ADDR isn't set explicitly, build it from SERVER_PORT
: "${REGISTRY_HTTP_ADDR:=0.0.0.0:${SERVER_PORT}}"
export REGISTRY_HTTP_ADDR

# Ensure storage path exists
: "${REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY:=/home/container/registry}"
mkdir -p "${REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY}"

# Create runtime config file
RUNTIME_CONFIG="/home/container/config.yml"
cat > "${RUNTIME_CONFIG}" <<EOF
version: 0.1

log:
  level: ${REGISTRY_LOG_LEVEL:-info}
  formatter: text
  fields:
    service: registry

storage:
  filesystem:
    rootdirectory: ${REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY}
EOF

# Handle authentication
HTPASSWD_FILE="/home/container/htpasswd"
if [ -n "${REGISTRY_AUTH_USERNAME}" ] && [ -n "${REGISTRY_AUTH_PASSWORD}" ]; then
    echo "[entrypoint] Setting up authentication for user: ${REGISTRY_AUTH_USERNAME}"
    htpasswd -Bbn "${REGISTRY_AUTH_USERNAME}" "${REGISTRY_AUTH_PASSWORD}" > "${HTPASSWD_FILE}"
    chmod 600 "${HTPASSWD_FILE}"
    
    # Add auth section to config
    cat >> "${RUNTIME_CONFIG}" <<EOF

auth:
  htpasswd:
    realm: Registry Realm
    path: ${HTPASSWD_FILE}
EOF
else
    echo "[entrypoint] WARNING: No authentication configured. Registry is publicly accessible!"
    echo "[entrypoint] Set REGISTRY_AUTH_USERNAME and REGISTRY_AUTH_PASSWORD to enable auth."
    rm -f "${HTPASSWD_FILE}"
fi

# Add HTTP section
cat >> "${RUNTIME_CONFIG}" <<EOF

http:
  addr: ${REGISTRY_HTTP_ADDR}
  headers:
    X-Content-Type-Options: [nosniff]

health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
EOF

echo "[entrypoint] Starting Docker Registry..."
echo "[entrypoint] Using configuration: ${RUNTIME_CONFIG}"
echo "[entrypoint] Data dir: ${REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY}"
echo "[entrypoint] HTTP addr: ${REGISTRY_HTTP_ADDR}"

# Start the registry (Alpine package binary is 'docker-registry')
exec docker-registry serve "${RUNTIME_CONFIG}"
