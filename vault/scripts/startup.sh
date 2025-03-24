#!/bin/sh

# Create necessary directories
mkdir -p /vault/logs
mkdir -p /vault/data
mkdir -p /vault/config

# Create Vault config
cat > /vault/config/vault.json << EOF
{
  "backend": {
    "file": {
      "path": "/vault/data"
    }
  },
  "listener": {
    "tcp": {
      "address": "0.0.0.0:8200",
      "tls_disable": 1
    }
  },
  "ui": true,
  "disable_mlock": true,
  "default_lease_ttl": "168h",
  "max_lease_ttl": "720h"
}
EOF

# Start Vault in development mode for ease of use
vault server -dev -dev-root-token-id="root-token" -dev-kv-v1 -config=/vault/config/vault.json
