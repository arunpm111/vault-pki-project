# Dynamic Certificate Generation with HashiCorp Vault

## Overview
This project demonstrates a complete Docker setup with HashiCorp Vault server and Vault agent configured to automatically generate certificates with dynamic hostnames, customizable IP addresses, and DNS names.

## What We've Accomplished

### ✅ 1. Docker Setup
- **Vault Server**: Running in dev mode with root token for easy testing
- **Vault Agent**: Configured to automatically fetch certificates using templates
- **Network**: Both containers communicate over a dedicated Docker network

### ✅ 2. PKI Configuration
- **PKI Secrets Engine**: Enabled and configured with a root CA
- **Certificate Role**: Created "example-dot-com" role allowing multi-domain support, IP SANs, and wildcards
- **Root Certificate**: Generated and stored in `/certs/ca.crt`
- **Policy**: Created `cert-policy` for certificate issuance permissions

### ✅ 3. Dynamic Templates with pkiCert
- **Template File**: `templates/cert.tpl` uses the `pkiCert` function instead of `secret`
- **Environment Variables**: Uses `HOSTNAME`, `IP_SANS` and `ALT_NAMES` for dynamic configuration
- **Template Logic**: Generates certificates with CN=`{hostname}.example.com` and custom SANs
- **Auto-Renewal**: Vault agent automatically processes the template and generates certificates

### ✅ 4. Tested Results

#### Test 1: hostname = "vault-agent"
```
Subject: CN=vault-agent.example.com
Subject Alternative Name: DNS:vault-agent.example.com
```

#### Test 2: hostname = "my-app-server"
```
Subject: CN=my-app-server.example.com
Subject Alternative Name: DNS:my-app-server.example.com
```

## Key Components

### Template (`templates/cert.tpl`)
```hcl
{{ with secret "pki/issue/example-dot-com" (printf "common_name=%s.example.com" (env "HOSTNAME")) "ttl=24h" }}
=== CERTIFICATE ===
{{ .Data.certificate }}

=== PRIVATE KEY ===
{{ .Data.private_key }}

=== ISSUING CA ===
{{ .Data.issuing_ca }}

=== SERIAL NUMBER ===
{{ .Data.serial_number }}
{{ end }}
```

### Vault Agent Configuration (`config/vault-agent.hcl`)
```hcl
vault {
  address = "http://vault-server:8200"
}

auto_auth {
  method "token_file" {
    config = {
      token_file_path = "/vault/token"
    }
  }
}

template {
  source = "/vault/templates/cert.tpl"
  destination = "/vault/certs/cert.pem"
  perms = 0644
}
```

## How to Use

1. **Start the services:**
   ```bash
   docker compose up -d
   ```

2. **Initialize PKI:**
   ```bash
   docker compose exec vault-server /scripts/setup-pki.sh
   ```

3. **Check generated certificate:**
   ```bash
   cat certs/cert.pem
   openssl x509 -in certs/cert.pem -noout -text | grep "Subject Alternative Name" -A2
   ```

4. **Generate custom certificates:**
   ```bash
   # Run the custom certificate demo script
   ./scripts/custom-cert-env.sh
   ```

## Benefits

- **Dynamic**: Certificate CN automatically matches container hostname
- **Automated**: No manual certificate generation required
- **Secure**: Uses HashiCorp Vault's PKI for certificate management
- **Scalable**: Easy to deploy with different hostnames across environments
- **Production-ready**: Can be adapted for production with proper authentication

## Files Generated

- `/certs/ca.crt` - Root CA certificate
- `/certs/cert.pem` - Complete certificate bundle (certificate + private key + CA + serial)

This setup demonstrates how to use HashiCorp Vault for automated certificate management with dynamic hostname resolution, perfect for containerized applications that need SSL/TLS certificates matching their runtime hostnames.
