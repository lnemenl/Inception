#!/bin/sh
# Generate self-signed SSL certificate
openssl req -x509 -nodes -days 365 \
    -subj "/C=FI/ST=Uusimaa/L=Helsinki/O=42/OU=Hive/CN=${DOMAIN_NAME}" \
    -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/private.key \
    -out /etc/nginx/ssl/public.crt
