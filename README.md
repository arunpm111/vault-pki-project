# Vault PKI Project

This project sets up a HashiCorp Vault server and a Vault agent configured to use the PKI secrets engine for certificate management. The following instructions will guide you through the setup and usage of the project.

## Project Structure

```
vault-pki-project
├── docker-compose.yml       # Defines the services for Vault server and agent
├── config
│   ├── vault-server.hcl     # Configuration for the Vault server
│   └── vault-agent.hcl      # Configuration for the Vault agent
├── templates
│   └── cert.tpl             # Template for generating certificates
├── scripts
│   ├── setup-pki.sh         # Script to enable PKI in Vault
│   └── custom-cert-env.sh   # Script to demonstrate custom certificate generation
├── certs                    # Directory for storing generated certificates
│   ├── ca.crt              # Generated CA certificate
│   └── cert.pem            # Generated server certificate
├── USING_PKICERT.md         # Documentation on using pkiCert function
├── SUMMARY.md               # Project summary
└── README.md                # Project documentation
```

## Prerequisites

- Docker and Docker Compose installed on your machine.
- Basic understanding of HashiCorp Vault and PKI concepts.

## Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd vault-pki-project
   ```

2. **Start the Services and Set Up PKI**
   Run the following commands to start the Vault server and agent, and set up PKI:
   ```bash
   # Start the docker containers
   docker compose up -d
   
   # Wait for Vault server to initialize (5-10 seconds)
   sleep 10
   
   # Configure PKI secrets engine
   docker compose exec vault-server /scripts/setup-pki.sh
   ```

3. **Verify Certificate Generation**
   After the services are running and PKI is set up, the Vault agent will automatically fetch certificates based on the template defined in `templates/cert.tpl`. The certificates will be stored in the `certs` directory.
   ```bash
   # Check the generated certificate
   ls -la certs/
   ```

4. **Generate Custom Certificates**
   You can generate custom certificates with specific IP addresses and domain names using environment variables:
   ```bash
   # Run the custom certificate script
   ./scripts/custom-cert-env.sh
   ```

## Usage

- The Vault server will be accessible at `http://localhost:8200`.
- The Vault agent will handle certificate requests and renewals as per the configuration.

### Customizing Certificates

You can customize certificates by setting environment variables:

```bash
# Set custom values for certificate attributes
export HOSTNAME="your-server-name"
export IP_SANS="127.0.0.1,192.168.1.10,10.0.0.1"
export ALT_NAMES="localhost,your-server-name.internal,*.staging.example.com"

# Start services with these environment variables
docker compose up -d
```

For more details on using the `pkiCert` function with environment variables, see the `USING_PKICERT.md` document.

## Results

After following the setup instructions, you should be able to see the Vault server running and issuing certificates as specified. The generated certificates will include:

1. A CA certificate in `/certs/ca.crt`
2. A server certificate in `/certs/cert.pem` with:
   - Common name based on the HOSTNAME environment variable
   - IP SANs based on the IP_SANS environment variable
   - DNS SANs based on the ALT_NAMES environment variable

## Troubleshooting

- If you encounter issues, check the logs of the Docker containers using:
  ```bash
  docker compose logs
  ```
- Make sure that any custom domain names you use are listed in the `allowed_domains` parameter of the PKI role in `scripts/setup-pki.sh`.
- Ensure that the Vault server is running before attempting to use the PKI features.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.