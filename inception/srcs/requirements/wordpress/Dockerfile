# Use the penultimate stable Alpine version
FROM alpine:3.20

# Install PHP, PHP-FPM, and dependencies
RUN apk update && apk add --no-cache \
    php83 php83-fpm php83-mysqli php83-curl php83-json php83-phar php83-mbstring \
    mariadb-client curl less wget && \
    rm -rf /var/cache/apk/*

# Create working directory
RUN mkdir -p /var/www/html && \
    chown -R nobody:nobody /var/www/html

# Set PHP memory limit
RUN echo "memory_limit = 256M" > /etc/php83/conf.d/custom.ini

# Copy configuration and scripts
COPY conf/www.conf /etc/php83/php-fpm.d/www.conf
COPY tools/init.sh /usr/local/bin/init.sh

# Set permissions
RUN chmod 644 /etc/php83/php-fpm.d/www.conf /etc/php83/conf.d/custom.ini && \
    chmod 755 /usr/local/bin/init.sh

# Expose PHP-FPM port
EXPOSE 9000

# Run initialization script
ENTRYPOINT ["/usr/local/bin/init.sh"]
