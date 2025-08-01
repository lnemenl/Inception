# Inception Project: Nginx Service Dockerfile
# This Dockerfile builds the image for the Nginx web server.

FROM alpine:3.20

# Install Nginx, OpenSSL (for certificate generation), and gettext (for `envsubst`).
# Switch to HTTP repositories, update, and install packages in a single layer.
RUN sed -i 's/https/http/g' /etc/apk/repositories && \
    apk update && \
    apk add --no-cache nginx openssl gettext

# Create the directory where Nginx runtime files will be stored.
RUN mkdir -p /run/nginx

# Copy all necessary files into the image.
COPY conf/nginx.conf.template /etc/nginx/nginx.conf.template
COPY tools/generate-certs.sh /usr/local/bin/generate-certs.sh
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

# Make all scripts executable.
RUN chmod +x /usr/local/bin/generate-certs.sh /usr/local/bin/entrypoint.sh

# Expose the HTTPS port.
EXPOSE 443

# Set the entrypoint to our new script, which handles all setup.
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
