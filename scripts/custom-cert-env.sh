#!/bin/bash
# filepath: /Users/arunpm111/vagent/vault-pki-project/scripts/custom-cert-env.sh

# Stop any running containers
docker compose down

# Run with custom IP SANs and alternative names
export HOSTNAME="custom-server"
export IP_SANS="127.0.0.1,10.0.0.5,192.168.10.50"
export ALT_NAMES="localhost,custom-server.internal,*.staging.example.com"

# Start services with the custom environment variables
docker compose up -d

# Give Vault server time to start
echo "Waiting for Vault server to start..."
sleep 5

# Initialize the PKI backend
echo "Setting up PKI in Vault..."
docker compose exec vault-server /scripts/setup-pki.sh

# Wait for the certificate to be generated
echo "Waiting for certificate generation..."
sleep 10

# Check if Vault agent is running and if the certificate has been generated
docker compose exec vault-agent ls -l /vault/certs || echo "Vault agent container is not accessible"

# Copy and check the certificate (with error handling)
if docker compose cp vault-agent:/vault/certs/cert.pem ./custom-cert.pem; then
  echo "Certificate successfully copied"
  # Display the certificate information
  echo "Certificate generated with custom values:"
  openssl x509 -in custom-cert.pem -noout -text | grep -A3 "Subject Alternative Name"
else
  echo "Failed to copy certificate - it may not have been generated yet"
  # Check logs for any issues
  echo "Checking Vault agent logs:"
  docker compose logs vault-agent | tail -20
fi

echo ""
echo "Full certificate stored at: ./custom-cert.pem"
