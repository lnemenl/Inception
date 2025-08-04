FROM alpine:3.19

# Install the Nginx server, OpenSSL (for generating SSL certificates),
# and `gettext` (which provides the `envsubst` utility used for configuration templating).
RUN sed -i 's/https/http/g' /etc/apk/repositories && \
    apk update && \
    apk add --no-cache nginx openssl gettext

# Create a directory for Nginx to store its runtime files, like its process ID.
RUN mkdir -p /run/nginx
# Copy the configuration template and all necessary scripts into the image.
COPY conf/nginx.conf.template /etc/nginx/nginx.conf.template
COPY tools/generate-certs.sh /usr/local/bin/generate-certs.sh
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
# Make all the scripts executable.
RUN chmod +x /usr/local/bin/generate-certs.sh /usr/local/bin/entrypoint.sh
# Document that the container listens on the standard HTTPS port.
EXPOSE 443
# Set the main command to run when the container starts.
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]