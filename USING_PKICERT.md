# Using `pkiCert` Function with IP SANs in Vault Agent Templates

This document describes how to properly use the `pkiCert` function in HashiCorp Vault Agent templates to generate certificates with IP Subject Alternative Names (SANs).

## Proper Template Syntax

The recommended syntax for using `pkiCert` with IP SANs is:

```hcl
{{ with pkiCert "pki/issue/role-name" 
    (printf "common_name=%s.example.com" (env "HOSTNAME"))
    "ttl=24h" 
    (printf "ip_sans=%s" (or (env "IP_SANS") "127.0.0.1,192.168.1.100"))
    (printf "alt_names=%s" (or (env "ALT_NAMES") "localhost,*.example.com"))
}}
=== CERTIFICATE ===
{{ .Cert }}

=== PRIVATE KEY ===
{{ .Key }}

=== ISSUING CA ===
{{ .CA }}
{{ end }}
```

## PKI Role Configuration

For the IP SANs to work, the PKI role must be configured to allow them:

```hcl
vault write pki/roles/example-dot-com \
    allowed_domains="example.com" \
    allow_subdomains=true \
    allow_ip_sans=true \
    allow_localhost=true \
    allow_wildcard_certificates=true \
    max_ttl="72h"
```

## Available Fields in `pkiCert`

The `pkiCert` function returns an object with only three available fields:

1. `.Cert` - The certificate in PEM format
2. `.Key` - The private key in PEM format
3. `.CA` - The issuing CA certificate in PEM format

Note that unlike the `secret` function, `pkiCert` does not provide access to the serial number through a `.SerialNumber` field.

## Benefits of `pkiCert` vs `secret`

- `pkiCert` is specifically designed for PKI certificates
- Better certificate lifecycle management
- More straightforward syntax for PKI operations
- Direct access to the relevant certificate components

## Example Certificate Output

A certificate generated with IP SANs will contain a Subject Alternative Name extension similar to:

```
X509v3 Subject Alternative Name: 
    DNS:*.example.com, DNS:localhost, DNS:my-app-server.example.com, IP Address:127.0.0.1, IP Address:192.168.1.100
```

## Common Issues

- Ensure the PKI role has `allow_ip_sans=true`
- Pass IP SANs as a separate parameter, not in the common_name string
- The field names in `pkiCert` differ from those in the `secret` function

## Using Environment Variables

You can make your certificate template more flexible by using environment variables:

1. For common name:
   ```
   (printf "common_name=%s.example.com" (env "HOSTNAME"))
   ```

2. For IP SANs:
   ```
   (printf "ip_sans=%s" (or (env "IP_SANS") "127.0.0.1,192.168.1.100"))
   ```

3. For alternative names:
   ```
   (printf "alt_names=%s" (or (env "ALT_NAMES") "localhost,*.example.com"))
   ```

The `or` function provides a default value if the environment variable is not set. In your docker-compose.yml, you can set these variables like:

```yaml
environment:
  - HOSTNAME=${HOSTNAME:-my-app-server}
  - IP_SANS=${IP_SANS:-127.0.0.1,192.168.1.100}
  - ALT_NAMES=${ALT_NAMES:-localhost,*.example.com}
```

This allows you to customize certificate attributes without modifying the template.

### Example Usage with Custom Environments

Here's an example of using environment variables to generate a certificate with custom SANs:

```bash
# Set custom values for certificate
export HOSTNAME="custom-server"
export IP_SANS="127.0.0.1,10.0.0.5,192.168.10.50"
export ALT_NAMES="localhost,custom-server.internal,*.staging.example.com"

# Start services with these environment variables
docker compose up -d
```

The resulting certificate will include:
- Common Name: custom-server.example.com
- IP SANs: 127.0.0.1, 10.0.0.5, 192.168.10.50
- DNS SANs: localhost, custom-server.internal, *.staging.example.com

### Important Role Configuration Note

When using custom domain names, make sure the PKI role allows them:

```
vault write pki/roles/example-dot-com \
    allowed_domains="example.com,internal,staging.example.com" \
    allow_subdomains=true \
    # ... other settings ...
```

If a domain is not in the allowed_domains list, certificate generation will fail with an error like:
```
subject alternate name custom-server.internal not allowed by this role
```
