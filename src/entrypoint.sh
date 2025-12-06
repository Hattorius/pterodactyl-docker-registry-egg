#!/usr/bin/env bash
set -e

# Path to registry config file
: "${REGISTRY_CONFIGURATION:=/etc/docker/registry/config.yml}"

# Prefer Pterodactyl's SERVER_PORT, otherwise fall back to 5000
: "${SERVER_PORT:=5000}"

# If REGISTRY_HTTP_ADDR isn't set explicitly, build it from SERVER_PORT
: "${REGISTRY_HTTP_ADDR:=0.0.0.0:${SERVER_PORT}}"
export REGISTRY_HTTP_ADDR

# Ensure storage path exists
: "${REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY:=/home/container/registry}"
mkdir -p "${REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY}"

# Handle authentication
HTPASSWD_FILE="/home/container/htpasswd"
if [ -n "${REGISTRY_AUTH_USERNAME}" ] && [ -n "${REGISTRY_AUTH_PASSWORD}" ]; then
    echo "[entrypoint] Setting up authentication for user: ${REGISTRY_AUTH_USERNAME}"
    htpasswd -Bbn "${REGISTRY_AUTH_USERNAME}" "${REGISTRY_AUTH_PASSWORD}" > "${HTPASSWD_FILE}"
    chmod 600 "${HTPASSWD_FILE}"
else
    echo "[entrypoint] WARNING: No authentication configured. Registry is publicly accessible!"
    echo "[entrypoint] Set REGISTRY_AUTH_USERNAME and REGISTRY_AUTH_PASSWORD to enable auth."
    # Remove htpasswd file if it exists to disable auth
    rm -f "${HTPASSWD_FILE}"
fi

echo "[entrypoint] Starting Docker Registry..."
echo "[entrypoint] Using configuration: ${REGISTRY_CONFIGURATION}"
echo "[entrypoint] Data dir: ${REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY}"
echo "[entrypoint] HTTP addr: ${REGISTRY_HTTP_ADDR}"

if [ -f "${REGISTRY_CONFIGURATION}" ]; then
    echo "[entrypoint] Config file exists."
else
    echo "[entrypoint] WARNING: Config file not found at ${REGISTRY_CONFIGURATION}"
fi

# Start the registry (Alpine package binary is 'docker-registry')
exec docker-registry serve "${REGISTRY_CONFIGURATION}"
