#!/bin/sh
# -----------------------------------------------------------------------------
# This script orchestrates the startup sequence for the Nginx container. It
# ensures that all prerequisites are met and configurations are in place
# before launching the main Nginx process.
# -----------------------------------------------------------------------------
set -e

# --- 1. Generate SSL Certificate ---
# WHAT FOR: Nginx requires its SSL certificate and key files to exist on startup,
#           or it will fail with an error. This command runs our certificate
#           generation script to ensure those files are present before Nginx
#           is ever started.
/usr/local/bin/generate-certs.sh

# --- 2. Substitute Environment Variables into Config ---
# WHAT FOR: To make our container reusable, we avoid hardcoding dynamic values
#           like the domain name. This command takes our configuration
#           *template* and injects the actual value of ${DOMAIN_NAME} from the
#           environment, producing the final nginx.conf that the server will use.
envsubst '${DOMAIN_NAME}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# --- 3. Start Nginx Server ---
# WHAT FOR: This is the final step that launches the web server.
#
#   - 'exec': This is critical. It replaces the current script process with the
#     Nginx process. This makes Nginx the main process (PID 1) of the
#     container, which allows Docker to manage its lifecycle correctly (e.g.,
#     sending stop signals directly to Nginx).
#
#   - '-g 'daemon off;'': This directive is mandatory for Docker. It forces
#     Nginx to run in the foreground. If we didn't use this, Nginx would
#     start in the background (daemonize), the script would immediately exit,
#     and Docker would think the container's job is finished and shut it down.
echo "==> Starting Nginx..."
exec nginx -g 'daemon off;'