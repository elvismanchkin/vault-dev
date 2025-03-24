# HashiCorp Vault Local Development Environment

This Docker Compose setup creates a local development environment for HashiCorp Vault with KV1 secret engine, demo secrets, and AppRole authentication method.

## Prerequisites

- Docker and Docker Compose installed
- `jq` installed (used in the initialization script)

## Directory Structure

```
.
├── docker-compose.yml
├── .env
└── vault/
    ├── config/
    ├── data/
    ├── logs/
    ├── credentials/
    └── scripts/
        ├── startup.sh
        └── initialize.sh
```

## Setup Instructions

1. Create the directory structure:

```bash
mkdir -p vault/config vault/data vault/logs vault/credentials vault/scripts
```

2. Copy the provided scripts to their respective locations:
   - `startup.sh` → `vault/scripts/startup.sh`
   - `initialize.sh` → `vault/scripts/initialize.sh`

3. Make the scripts executable:

```bash
chmod +x vault/scripts/startup.sh vault/scripts/initialize.sh
```

4. Start the environment:

```bash
docker-compose up -d
```

5. View AppRole credentials:

```bash
cat vault/credentials/approle_creds.txt
```

## Features

- **KV1 Secret Engine**: Uses Vault's KV version 1 secret engine by default
- **Demo Secret**: Creates a demo secret at `secret/demo` with username, password, and environment
- **AppRole Authentication**: Sets up AppRole auth method with appropriate policies
- **Credentials**: Automatically generates and outputs Role ID and Secret ID

## Accessing Vault

- **UI**: http://localhost:8200 (token: `root-token`)
- **CLI**: Using the Vault CLI with `VAULT_ADDR=http://localhost:8200` and `VAULT_TOKEN=root-token`

## Authenticating with AppRole

```bash
# Get the Role ID and Secret ID
ROLE_ID=$(cat vault/credentials/approle_creds.txt | grep "Role ID" | cut -d ' ' -f 3)
SECRET_ID=$(cat vault/credentials/approle_creds.txt | grep "Secret ID" | cut -d ' ' -f 3)

# Login with AppRole
vault write auth/approle/login role_id=$ROLE_ID secret_id=$SECRET_ID

# Using the token to access the demo secret
VAULT_TOKEN=<obtained-token> vault kv get secret/demo
```

## Stopping the Environment

```bash
docker-compose down
```

To completely reset the environment including volumes:

```bash
docker-compose down -v
rm -rf vault/data/* vault/logs/* vault/config/* vault/credentials/*
```
