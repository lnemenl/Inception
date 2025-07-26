#!/bin/sh
# Inception Project: SSL Certificate Generation Script

set -e

CERT_DIR="/etc/nginx/ssl"
KEY_FILE="${CERT_DIR}/private.key"
CERT_FILE="${CERT_DIR}/public.crt"

# Create the certificate directory if it doesn't exist.
mkdir -p "$CERT_DIR"

# Idempotency Check: Only generate certificates if they don't already exist.
if [ -f "$KEY_FILE" ] && [ -f "$CERT_FILE" ]; then
    echo "✅ SSL certificates already exist. Skipping generation."
else
    echo "🔐 Generating self-signed SSL certificate..."

    # Use OpenSSL to generate a new self-signed certificate and private key.
    # -x509: Output a self-signed certificate instead of a certificate request.
    # -nodes: Don't encrypt the private key (no passphrase).
    # -days 365: The certificate will be valid for one year.
    # -newkey rsa:2048: Generate a new 2048-bit RSA private key.
    # -subj: Sets the subject information for the certificate non-interactively.
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout "${KEY_FILE}" \
        -out "${CERT_FILE}" \
        -subj "/C=FI/ST=Uusimaa/L=Espoo/O=42/OU=Student/CN=${DOMAIN_NAME}"

    echo "✅ SSL certificate generated successfully."
fi