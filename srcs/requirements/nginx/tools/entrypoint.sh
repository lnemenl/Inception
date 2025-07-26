#!/bin/sh
# Inception Project: Nginx Entrypoint Script

set -e # Exit immediately if any command fails.

# 1. Generate SSL Certificates
# This calls another script to create the self-signed certificate and key
# if they don't already exist.
/usr/local/bin/generate-certs.sh

# 2. Substitute Environment Variables
# This command takes the nginx.conf.template, replaces any shell variables
# (like ${DOMAIN_NAME}) with their actual values from the environment,
# and creates the final nginx.conf file that Nginx will use.
envsubst '${DOMAIN_NAME}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# 3. Start Nginx Server
# Use `exec` to replace this script's process with the Nginx process.
# This makes Nginx the main process (PID 1) of the container.
# The `-g 'daemon off;'` directive tells Nginx to run in the foreground,
# which is essential for Docker containers.
echo "==> Starting Nginx..."
exec nginx -g 'daemon off;'