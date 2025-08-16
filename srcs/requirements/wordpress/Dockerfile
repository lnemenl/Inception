# -----------------------------------------------------------------------------
# WHAT IS THIS ALL FOR:
# This file builds the image for our WordPress application. The primary goals
# are security, optimization, and automation. We use a multi-stage build to
# create the smallest possible final image.
# The image will contain PHP-FPM (to run the code)
# and WP-CLI (to automate the installation).
# -----------------------------------------------------------------------------

# --- Stage 1: The "Builder" ---
# WHAT FOR: The sole purpose of this stage is to obtain a single file: the
#           WP-CLI command-line tool. We do this in an isolated environment
#           so that the tools needed to get this file (like 'wget' and the
#           apk package cache) are completely discarded and never touch our
#           final, clean production image.
FROM alpine:3.19 AS builder
RUN sed -i 's/https/http/g' /etc/apk/repositories && \
    apk update && \
    apk add --no-cache wget && \
    wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /wp-cli.phar

# --- Stage 2: The Final Production Image ---
# This is where we build the actual image that will run in production.
FROM alpine:3.19

# --- Install Runtime Dependencies ---
# WHAT FOR: To install only the bare minimum required to *run* WordPress.
#   - php83-fpm: The engine that executes all WordPress PHP code.
#   - php83-*: The specific extensions WordPress needs to connect to the
#     database (mysqli), handle images, process JSON, etc.
#   - netcat: A tiny, lightweight networking tool. Our init script uses it
#     to check if the MariaDB port is open before trying to connect, which
#     is more reliable and efficient than a simple 'sleep'.
#   - mariadb-client: Provides tools that WP-CLI depends on to communicate
#     with the database.
RUN sed -i 's/https/http/g' /etc/apk/repositories && \
    apk update && \
    apk add --no-cache \
    php83 \
    php83-fpm \
    php83-mysqli \
    php83-curl \
    php83-json \
    php83-mbstring \
    php83-phar \
    mariadb-client \
    netcat-openbsd

# Create a symlink to make the 'php' command available directly.
RUN ln -s /usr/bin/php83 /usr/bin/php

# --- Configure the Image ---
# WHAT FOR: This is the payoff for the multi-stage build. We are copying
#           *only the final product* (wp-cli.phar) from the builder stage.
#           This lets us use the tool without inheriting any of the bloat or
#           potential vulnerabilities from the tools used to download it.
COPY --from=builder /wp-cli.phar /usr/local/bin/wp

# Make the WP-CLI tool executable so we can run it.
RUN chmod +x /usr/local/bin/wp

# Create the web root directory.
RUN mkdir -p /var/www/html

# Copy our custom configurations and the main startup script into the image.
COPY conf/www.conf /etc/php83/php-fpm.d/www.conf
COPY conf/custom.ini /etc/php83/conf.d/custom.ini
COPY tools/init.sh /usr/local/bin/init.sh

# Apply correct permissions and make the startup script executable.
RUN chmod 644 /etc/php83/php-fpm.d/www.conf /etc/php83/conf.d/custom.ini && \
    chmod +x /usr/local/bin/init.sh

# WHAT FOR: To set the default location for all subsequent commands. Our init
#           script needs to run WP-CLI commands, and WP-CLI operates on the
#           files in the current directory. This ensures the script runs in
#           the correct context without needing to 'cd' into it first.
WORKDIR /var/www/html

# Document the port that PHP-FPM listens on for requests from Nginx.
EXPOSE 9000

# WHAT FOR: To specify the command that runs when the container starts. We use
#           a custom script instead of just 'php-fpm' because we need to
#           perform critical setup tasks first: wait for the database, download
#           WordPress core files, create wp-config.php, and run the installer.
#           Only after this automation is complete will the script start the
#           main PHP-FPM service.
ENTRYPOINT ["/usr/local/bin/init.sh"]