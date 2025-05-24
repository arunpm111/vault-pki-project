{{ with pkiCert "pki/issue/example-dot-com" 
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