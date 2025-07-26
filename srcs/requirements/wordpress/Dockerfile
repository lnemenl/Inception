# Inception Project: WordPress Service Dockerfile
# This Dockerfile builds the image for the WordPress application server using PHP-FPM.

# Use a specific, stable version of Alpine Linux as the base image.
FROM alpine:3.20

# Install PHP-FPM, all necessary PHP extensions for WordPress to function correctly,
# and the `netcat` utility for our simple, reliable healthcheck.
# `--no-cache` is used to keep the final image size small.
RUN apk add --no-cache \
    php83 \
    php83-fpm \
    php83-mysqli \
    php83-curl \
    php83-json \
    php83-mbstring \
    php83-phar \
    mariadb-client \
    wget \
    netcat-openbsd

# Create the web root directory where WordPress files will live.
RUN mkdir -p /var/www/html

# Copy all necessary configuration and script files into the image.
COPY conf/www.conf /etc/php83/php-fpm.d/www.conf
COPY conf/custom.ini /etc/php83/conf.d/custom.ini
COPY tools/init.sh /usr/local/bin/init.sh
COPY healthcheck.sh /usr/local/bin/healthcheck.sh

# Set correct file permissions for configs and make the scripts executable.
# Combining these into a single RUN command creates a more efficient image layer.
RUN chmod 644 /etc/php83/php-fpm.d/www.conf /etc/php83/conf.d/custom.ini && \
    chmod +x /usr/local/bin/init.sh /usr/local/bin/healthcheck.sh

# Download WP-CLI, the powerful command-line interface for WordPress.
# We will use this in our init.sh script to automate the entire installation process.
RUN wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp && \
    chmod +x /usr/local/bin/wp

# Set the working directory. Any subsequent commands (like in init.sh)
# will run from this path.
WORKDIR /var/www/html

# Expose the PHP-FPM port. This allows the Nginx container to connect to it.
EXPOSE 9000

# Set the entrypoint to our initialization script. This script will configure
# and then start the PHP-FPM server.
ENTRYPOINT ["/usr/local/bin/init.sh"]