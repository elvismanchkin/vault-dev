#!/bin/sh
set -e

# Wait for Vault to be ready
echo "Waiting for Vault to start..."
sleep 5

# Make sure Vault is unsealed and ready
until vault status > /dev/null 2>&1; do
  echo "Waiting for Vault to become available..."
  sleep 2
done

echo "Vault is ready. Configuring..."

# Create demo secret
echo "Creating demo secret in KV1 store..."
vault kv put secret/demo username="demo-user" password="demo-password" environment="local"
vault kv get secret/demo

# Enable AppRole auth method
echo "Enabling AppRole authentication..."
vault auth enable approle

# Create a policy for demo secret access
echo "Creating 'demo-policy' for accessing demo secret..."
cat > /tmp/demo-policy.hcl << EOF
path "secret/demo" {
  capabilities = ["read", "list"]
}
EOF

vault policy write demo-policy /tmp/demo-policy.hcl

# Create an AppRole with the demo policy
echo "Creating AppRole with demo-policy attached..."
vault write auth/approle/role/demo-role \
  token_policies="demo-policy" \
  token_ttl=1h \
  token_max_ttl=4h \
  secret_id_ttl=10m \
  secret_id_num_uses=40

# Get RoleID
echo "Retrieving RoleID..."
ROLE_ID=$(vault read -format=json auth/approle/role/demo-role/role-id | jq -r .data.role_id)

# Generate SecretID
echo "Generating SecretID..."
SECRET_ID=$(vault write -format=json -f auth/approle/role/demo-role/secret-id | jq -r .data.secret_id)

# Save credentials to file for retrieval
mkdir -p /vault/credentials
cat > /vault/credentials/approle_creds.txt << EOF
Role ID: $ROLE_ID
Secret ID: $SECRET_ID
EOF

# Print credentials
echo "======================================================="
echo "AppRole Authentication Credentials"
echo "======================================================="
echo "Role ID: $ROLE_ID"
echo "Secret ID: $SECRET_ID"
echo "======================================================="
echo "These credentials have been saved to /vault/credentials/approle_creds.txt"
echo "======================================================="

# Create a test token to verify everything works
echo "Testing AppRole login..."
TEST_TOKEN=$(vault write -format=json auth/approle/login \
  role_id=$ROLE_ID \
  secret_id=$SECRET_ID | jq -r .auth.client_token)

echo "Verifying access to the demo secret with the AppRole token..."
VAULT_TOKEN=$TEST_TOKEN vault kv get secret/demo

echo "Vault configuration complete!"
