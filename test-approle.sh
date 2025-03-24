#!/bin/bash
set -e

# Ensure credential file exists
if [ ! -f ./vault/credentials/approle_creds.txt ]; then
  echo "Error: Credentials file not found. Make sure Vault is initialized properly."
  exit 1
fi

# Extract Role ID and Secret ID from credentials file
ROLE_ID=$(grep "Role ID" ./vault/credentials/approle_creds.txt | cut -d ' ' -f 3)
SECRET_ID=$(grep "Secret ID" ./vault/credentials/approle_creds.txt | cut -d ' ' -f 3)

echo "Using Role ID: $ROLE_ID"
echo "Using Secret ID: $SECRET_ID"
echo

# Get a token using AppRole login
echo "Attempting login with AppRole credentials..."
TOKEN=$(curl -s \
  --request POST \
  --data "{\"role_id\":\"$ROLE_ID\",\"secret_id\":\"$SECRET_ID\"}" \
  http://localhost:8200/v1/auth/approle/login | jq -r '.auth.client_token')

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
  echo "Error: Failed to authenticate with AppRole"
  exit 1
fi

echo "Successfully authenticated. Token received!"
echo

# Use the token to get the demo secret
echo "Trying to access the demo secret with the token..."
curl -s \
  --header "X-Vault-Token: $TOKEN" \
  http://localhost:8200/v1/secret/demo | jq

echo
echo "If you see the secret data above, everything is working correctly!"
