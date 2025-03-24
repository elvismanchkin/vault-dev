#!/bin/sh
# Simple setup script for HashiCorp Vault

echo "Waiting for Vault to initialize..."
sleep 3

# Test connection to Vault with retries
for i in $(seq 1 10); do
  echo "Attempt $i: Connecting to Vault..."
  if vault status > /dev/null 2>&1; then
    echo "Connected to Vault successfully!"
    break
  fi

  if [ $i -eq 10 ]; then
    echo "Failed to connect to Vault after 10 attempts"
    exit 1
  fi

  sleep 2
done

echo "Vault server is ready!"

# Create demo secret
echo "Creating demo secret in KV1 store..."
vault kv put secret/demo username="demo-user" password="demo-password" environment="local"
echo "Demo secret created. Reading back:"
vault kv get secret/demo

# Enable AppRole auth
echo "Enabling AppRole authentication..."
vault auth enable approle

# Create a policy for demo secret access
echo "Creating demo-policy for accessing demo secret..."
cat > /tmp/demo-policy.hcl << EOF
path "secret/demo" {
  capabilities = ["read", "list"]
}
EOF

vault policy write demo-policy /tmp/demo-policy.hcl

# Create AppRole with the policy
echo "Creating AppRole with demo-policy attached..."
vault write auth/approle/role/demo-role \
  token_policies="demo-policy" \
  token_ttl=1h \
  token_max_ttl=4h \
  secret_id_ttl=24h

# Verify AppRole creation
echo "Verifying AppRole configuration:"
vault read auth/approle/role/demo-role

# Use temporary files to store output
mkdir -p /tmp/vault-output

# Get RoleID
echo "Retrieving RoleID..."
vault read -format=table auth/approle/role/demo-role/role-id > /tmp/vault-output/role-id.txt
ROLE_ID=$(grep 'role_id' /tmp/vault-output/role-id.txt | awk '{print $2}')

# Generate SecretID
echo "Generating SecretID..."
vault write -f -format=table auth/approle/role/demo-role/secret-id > /tmp/vault-output/secret-id.txt
SECRET_ID=$(grep 'secret_id ' /tmp/vault-output/secret-id.txt | awk '{print $2}')

# Print credentials
echo "======================================================="
echo "AppRole Authentication Credentials"
echo "======================================================="
echo "Role ID: $ROLE_ID"
echo "Secret ID: $SECRET_ID"
echo "======================================================="

# Test AppRole login
echo "Testing AppRole login..."
vault write -format=table auth/approle/login \
  role_id="$ROLE_ID" \
  secret_id="$SECRET_ID" > /tmp/vault-output/login.txt

if grep -q "token " /tmp/vault-output/login.txt; then
  TEST_TOKEN=$(grep "token " /tmp/vault-output/login.txt | head -1 | awk '{print $2}')
  echo "Successfully authenticated with AppRole!"
  echo "Token: $TEST_TOKEN"

  echo "Accessing demo secret with AppRole token:"
  VAULT_TOKEN="$TEST_TOKEN" vault kv get secret/demo
else
  echo "Failed to authenticate with AppRole"
  cat /tmp/vault-output/login.txt
fi

# Clean up temporary files
rm -rf /tmp/vault-output

echo "Vault configuration complete!"
