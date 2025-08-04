#!/bin/sh
set -e

CERT_DIR="/etc/nginx/ssl"
KEY_FILE="${CERT_DIR}/private.key"
CERT_FILE="${CERT_DIR}/public.crt"

mkdir -p "$CERT_DIR"

# This `if` block makes the script "idempotent". This means it can be run many
# times, but it will only perform its main action (generating certs) once.
# It checks if the certificate and key files already exist before trying to create them.
if [ -f "$KEY_FILE" ] && [ -f "$CERT_FILE" ]; then
    echo "✅ SSL certificates already exist. Skipping generation."
else
    echo "🔐 Generating self-signed SSL certificate..."

    # `openssl req`: The OpenSSL command to create certificate requests and certificates.
    #   - `-x509`: Creates a self-signed certificate.
    #   - `-nodes`: "No DES". Creates a private key that is not encrypted with a passphrase,
    #     so the server can start automatically without human intervention.
    #   - `-days 365`: Sets the certificate's validity period.
    #   - `-newkey rsa:2048`: Generates a new 2048-bit RSA private key.
    #   - `-subj "..."`: Provides the certificate's subject information non-interactively.
    #     The `CN` (Common Name) must match your domain name.
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout "${KEY_FILE}" \
        -out "${CERT_FILE}" \
        -subj "/C=FI/ST=Uusimaa/L=Espoo/O=42/OU=Student/CN=${DOMAIN_NAME}"

    echo "✅ SSL certificate generated successfully."
fi