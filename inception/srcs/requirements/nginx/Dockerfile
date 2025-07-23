# Use the penultimate stable Alpine version
FROM alpine:3.20

# Install NGINX and OpenSSL
RUN apk update && apk add --no-cache nginx openssl gettext && \
    rm -rf /var/cache/apk/*

# Create directories
RUN mkdir -p /etc/nginx/ssl /var/log/nginx /var/www/html && \
    chown -R nginx:nginx /var/log/nginx /var/www/html

# Generate SSL certificates
COPY tools/generate-certs.sh /usr/local/bin/generate-certs.sh
RUN chmod +x /usr/local/bin/generate-certs.sh && \
    /usr/local/bin/generate-certs.sh

# Copy and process NGINX configuration
COPY conf/nginx.conf.template /etc/nginx/templates/nginx.conf.template
RUN export DOMAIN_NAME=${DOMAIN_NAME:-rkhakimu.42.fr} && \
    envsubst '${DOMAIN_NAME}' < /etc/nginx/templates/nginx.conf.template > /etc/nginx/nginx.conf && \
    chmod 644 /etc/nginx/nginx.conf

# Expose HTTPS port
EXPOSE 443

# Start NGINX in foreground
CMD ["nginx", "-g", "daemon off;"]
