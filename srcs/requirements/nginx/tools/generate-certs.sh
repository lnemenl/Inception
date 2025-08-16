#!/bin/sh
# -----------------------------------------------------------------------------
# This script creates a self-signed SSL certificate and private key, allowing
# the Nginx server to provide a secure HTTPS connection for local development.
# -----------------------------------------------------------------------------

set -e

CERT_DIR="/etc/nginx/ssl"
KEY_FILE="${CERT_DIR}/private.key"
CERT_FILE="${CERT_DIR}/public.crt"

# Create the target directory if it doesn't exist.
mkdir -p "$CERT_DIR"

# --- Idempotency Check ---
# WHAT: Checks if the certificate and key files already exist.
# WHY:  This ensures that the certificate is generated only once, on the first
#       container startup. On subsequent restarts, this script will do
#       nothing, preserving the existing certificate.
if [ -f "$KEY_FILE" ] && [ -f "$CERT_FILE" ]; then
    echo "✅ SSL certificates already exist. Skipping generation."
else
    echo "🔐 Generating self-signed SSL certificate..."

    # --- Certificate Generation ---
    # WHAT: Generate a new self-signed SSL certificate and a private key.
    # HOW:  The 'openssl req' command creates a certificate request.
    #         - '-x509':         Outputs a self-signed certificate instead of a request.
    #         - '-nodes':        (No DES) Creates a private key without a password.
    #                            This is CRUCIAL for an automated server setup, as it
    #                            allows Nginx to start without manual input.
    #         - '-days 365':     Sets the certificate's validity period to one year.
    #         - '-newkey rsa:2048': Generates a new 2048-bit RSA private key.
    #         - '-subj "..."':   Provides the certificate's subject information
    #                            non-interactively. The Common Name (CN) must
    #                            match our domain name.
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout "${KEY_FILE}" \
        -out "${CERT_FILE}" \
        -subj "/C=FI/ST=Uusimaa/L=Espoo/O=42/OU=Student/CN=${DOMAIN_NAME}"

    echo "✅ SSL certificate generated successfully."
fi