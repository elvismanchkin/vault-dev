# HashiCorp Vault with AppRole - Local Development

This setup provides a local HashiCorp Vault instance with:
- KV version 1 secret engine enabled by default
- A demo secret automatically created
- AppRole authentication method configured with access to the demo secret
- Role ID and Secret ID automatically generated and displayed

## Files

- `docker-compose.yml` - Docker Compose configuration for Vault
- `setup.sh` - Script that configures Vault with AppRole and secrets

## Setup Instructions

1. Save both files to the same directory
2. Make the setup script executable:
```bash
chmod +x setup.sh
```
3. Start the environment:
```bash
docker-compose up
```

The setup process will:
1. Start a Vault server in dev mode with KV1 enabled
2. Create a demo secret at `secret/demo`
3. Enable AppRole authentication
4. Configure a policy allowing read access to the demo secret
5. Create an AppRole with the policy
6. Output the Role ID and Secret ID
7. Test authentication using the credentials

## Using AppRole Authentication

Once the setup is complete, you can authenticate using the displayed Role ID and Secret ID:

```bash
# With the Vault CLI
export VAULT_ADDR=http://localhost:8200
vault write auth/approle/login \
  role_id=YOUR_ROLE_ID \
  secret_id=YOUR_SECRET_ID

# Using curl
curl -X POST \
  -d '{"role_id":"YOUR_ROLE_ID","secret_id":"YOUR_SECRET_ID"}' \
  http://localhost:8200/v1/auth/approle/login
```

## Accessing the Demo Secret

After authentication, you can access the demo secret:

```bash
# With the Vault CLI
VAULT_TOKEN=YOUR_TOKEN vault kv get secret/demo

# Using curl
curl -H "X-Vault-Token: YOUR_TOKEN" \
  http://localhost:8200/v1/secret/demo
```

## Web UI Access

You can access the Vault UI at http://localhost:8200

Login with:
- Method: Token
- Token: root-token

## Stopping and Cleaning Up

To stop the containers:
```bash
docker-compose down
```

To completely reset the environment:
```bash
docker-compose down
rm -rf data/
```
