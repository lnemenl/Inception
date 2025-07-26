# --- Builder Stage ---
# This stage downloads the necessary tools and files.
FROM alpine:3.20 AS builder

# Install wget and download WP-CLI.
RUN apk add --no-cache wget && \
    wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /wp-cli.phar

# --- Final Stage ---
# This is the clean, final image for our application.
FROM alpine:3.20

# Only install the packages absolutely required for running the application.
# Notice that `wget` is not needed here.
RUN apk add --no-cache \
    php83 \
    php83-fpm \
    php83-mysqli \
    php83-curl \
    php83-json \
    php83-mbstring \
    php83-phar \
    mariadb-client \
    netcat-openbsd

# Copy the WP-CLI tool from the 'builder' stage.
COPY --from=builder /wp-cli.phar /usr/local/bin/wp

# Now, continue with the rest of the setup as before.
RUN chmod +x /usr/local/bin/wp

RUN mkdir -p /var/www/html
COPY conf/www.conf /etc/php83/php-fpm.d/www.conf
COPY conf/custom.ini /etc/php83/conf.d/custom.ini
COPY tools/init.sh /usr/local/bin/init.sh
COPY healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod 644 /etc/php83/php-fpm.d/www.conf /etc/php83/conf.d/custom.ini && \
    chmod +x /usr/local/bin/init.sh /usr/local/bin/healthcheck.sh

WORKDIR /var/www/html
EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/init.sh"]