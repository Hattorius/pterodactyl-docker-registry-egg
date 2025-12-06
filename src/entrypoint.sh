#!/usr/bin/env bash
set -e

# HTTPS Port (default: 5443)
: "${REGISTRY_HTTPS_PORT:=5443}"

# Ensure storage path exists
: "${REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY:=/home/container/registry}"
mkdir -p "${REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY}"

# TLS certificate paths (in Pterodactyl's persistent /home/container)
TLS_CERT="/home/container/registry.crt"
TLS_KEY="/home/container/registry.key"

# Generate self-signed certificate if it doesn't exist
if [ ! -f "${TLS_CERT}" ] || [ ! -f "${TLS_KEY}" ]; then
    echo "[entrypoint] Generating self-signed certificate..."
    openssl req -newkey rsa:4096 -nodes -sha256 \
        -keyout "${TLS_KEY}" \
        -x509 -days 365 \
        -out "${TLS_CERT}" \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=registry" \
        -addext "subjectAltName=IP:0.0.0.0"
    chmod 600 "${TLS_KEY}"
    chmod 644 "${TLS_CERT}"
    echo "[entrypoint] Certificate generated and saved to ${TLS_CERT}"
    echo "[entrypoint] Download this certificate to trust it on Docker clients"
else
    echo "[entrypoint] Using existing certificate at ${TLS_CERT}"
fi

LISTEN_ADDR="0.0.0.0:${REGISTRY_HTTPS_PORT}"
export REGISTRY_HTTP_ADDR="${LISTEN_ADDR}"

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
# Add HTTP section with TLS
cat >> "${RUNTIME_CONFIG}" <<EOF

http:
  addr: ${REGISTRY_HTTP_ADDR}
  headers:
    X-Content-Type-Options: [nosniff]
  tls:
    certificate: ${TLS_CERT}
    key: ${TLS_KEY}

health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
EOF[ -n "${AUTH_USERNAME}" ] && [ -n "${AUTH_PASSWORD}" ]; then
    echo "[entrypoint] Setting up authentication for user: ${AUTH_USERNAME}"
    htpasswd -Bbn "${AUTH_USERNAME}" "${AUTH_PASSWORD}" > "${HTPASSWD_FILE}"
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

echo "[entrypoint] Starting Docker Registry..."
echo "[entrypoint] Protocol: ${PROTOCOL}"
echo "[entrypoint] Using configuration: ${RUNTIME_CONFIG}"
echo "[entrypoint] Data dir: ${REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY}"
echo "[entrypoint] Listen addr: ${REGISTRY_HTTP_ADDR}"

health:
  storagedriver:
    enabled: true
echo "[entrypoint] Starting Docker Registry..."
echo "[entrypoint] Protocol: HTTPS"
echo "[entrypoint] Using configuration: ${RUNTIME_CONFIG}"
echo "[entrypoint] Data dir: ${REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY}"
echo "[entrypoint] Listen addr: ${REGISTRY_HTTP_ADDR}"
echo "[entrypoint] Certificate: ${TLS_CERT}"
echo "[entrypoint] Using configuration: ${RUNTIME_CONFIG}"
echo "[entrypoint] Data dir: ${REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY}"
echo "[entrypoint] HTTP addr: ${REGISTRY_HTTP_ADDR}"
echo "[entrypoint] --- Config file contents ---"
cat "${RUNTIME_CONFIG}"
echo "[entrypoint] --- End of config ---"

# Start the registry (Alpine package binary is 'docker-registry')
exec docker-registry serve "${RUNTIME_CONFIG}"
