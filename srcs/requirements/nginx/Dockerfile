# -----------------------------------------------------------------------------
# This Dockerfile builds a lightweight, custom Nginx image that will act as
# the TLS termination point and reverse proxy for the WordPress service.
# -----------------------------------------------------------------------------

# Use Alpine Linux as the base for a minimal and more secure final image.
FROM alpine:3.19

# --- Install Packages ---
# WHAT: Install Nginx, OpenSSL, and the 'gettext' package.
# WHY:
#   - nginx:   The web server daemon.
#   - openssl: Required by our script to generate the self-signed SSL cert.
#   - gettext: Provides the 'envsubst' utility, which our entrypoint script
#              uses to dynamically inject environment variables (like the
#              domain name) into the configuration file.
RUN sed -i 's/https/http/g' /etc/apk/repositories && \
    apk update && \
    apk add --no-cache nginx openssl gettext

# Create a non-persistent directory that Nginx requires for runtime state files.
RUN mkdir -p /run/nginx

# Copy all necessary configuration and script files into the image.
COPY conf/nginx.conf.template /etc/nginx/nginx.conf.template
COPY tools/generate-certs.sh /usr/local/bin/generate-certs.sh
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

# Make the helper scripts executable.
RUN chmod +x /usr/local/bin/generate-certs.sh /usr/local/bin/entrypoint.sh

# Document that the container will listen on the standard HTTPS port.
EXPOSE 443

# Set the entrypoint script as the main command to run when the container starts.
# This script will handle the final setup steps before starting Nginx.
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]