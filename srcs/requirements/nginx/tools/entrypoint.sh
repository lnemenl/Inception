#!/bin/sh
set -e
# 1. Call the other script to generate the self-signed SSL certificate.
#    This is done first to ensure the certificate exists before Nginx starts.
/usr/local/bin/generate-certs.sh
# 2. This command performs the configuration templating.
#    - `envsubst '${DOMAIN_NAME}'`: This utility reads from standard input and
#      replaces any shell variable placeholders (like `${DOMAIN_NAME}`) with their
#      actual values from the environment.
#    - `< /etc/nginx/nginx.conf.template`: Redirects the content of the template file
#      to be the standard input for `envsubst`.
#    - `> /etc/nginx/nginx.conf`: Redirects the final output (the processed config)
#      into the real configuration file that Nginx will use.
envsubst '${DOMAIN_NAME}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
# 3. Use `exec` to make Nginx the main process (PID 1) of the container.
#    - `nginx -g 'daemon off;'`: Starts the Nginx server.
#    - `-g 'daemon off;'`: This is a crucial directive that tells Nginx to run in the
#      FOREGROUND. This is required for Docker, as it would otherwise "daemonize"
#      (run in the background) and cause the container to exit.
echo "==> Starting Nginx..."
exec nginx -g 'daemon off;'