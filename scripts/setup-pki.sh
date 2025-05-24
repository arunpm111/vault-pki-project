#!/bin/sh
set -e

# Configure environment
export VAULT_ADDR=http://vault-server:8200
export VAULT_TOKEN=root

# Wait for Vault to be ready
echo "Waiting for Vault server to start..."
until vault status > /dev/null 2>&1; do
  sleep 1
done

# Enable the PKI secrets engine
echo "Enabling PKI secrets engine..."
vault secrets enable pki

# Configure PKI settings
echo "Configuring PKI secrets engine..."
vault secrets tune -max-lease-ttl=87600h pki

# Generate the root certificate
echo "Generating root certificate..."
vault write -field=certificate pki/root/generate/internal \
    common_name="example.com" \
    ttl=87600h > /certs/ca.crt

# Configure the PKI URLs
echo "Configuring PKI URLs..."
vault write pki/config/urls \
    issuing_certificates="http://vault-server:8200/v1/pki/ca" \
    crl_distribution_points="http://vault-server:8200/v1/pki/crl"

# Create a role for the PKI engine
echo "Creating role for issuing certificates..."
vault write pki/roles/example-dot-com \
    allowed_domains="example.com,internal,staging.example.com" \
    allow_subdomains=true \
    allow_ip_sans=true \
    allow_localhost=true \
    allow_wildcard_certificates=true \
    max_ttl="72h"

# Create a policy for the Vault agent
echo "Creating policy for certificate issuance..."
vault policy write cert-policy - <<EOF
path "pki/issue/*" {
  capabilities = ["create", "update"]
}
path "pki/cert/*" {
  capabilities = ["read"]
}
EOF

echo "PKI setup complete!"