pid_file = "/tmp/vault-agent-pid"

exit_after_auth = false

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