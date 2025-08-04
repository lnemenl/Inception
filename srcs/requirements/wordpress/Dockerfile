#
# This Dockerfile uses a "multi-stage build", which is a technique to keep the
# final image as small and secure as possible. It works by using one or more
# temporary stages to build assets, and then copying only the necessary files
# into a clean final stage.
#

# --- Stage 1: The "Builder" ---
# `FROM alpine:3.19 AS builder`: This starts the first stage.
#   - `AS builder`: This gives the stage a name, `builder`. We will use this name later
#     to reference this stage and copy files from it.
# The ONLY purpose of this stage is to download the `wp-cli` tool.
FROM alpine:3.19 AS builder
# This `RUN` command does two things:
#  1. `apk add --no-cache wget`: Installs the `wget` command-line tool for downloading files.
#  2. `wget ...`: Uses `wget` to download the WordPress Command Line Interface (wp-cli)
#     from its official repository and save it as `/wp-cli.phar`.
RUN sed -i 's/https/http/g' /etc/apk/repositories && \
    apk update && \
    apk add --no-cache wget && \
    wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /wp-cli.phar

# --- Stage 2: The Final Production Image ---
# `FROM alpine:3.19`: This line starts a NEW, completely clean build stage.
#   Everything from the `builder` stage above is now discarded, except for what we
#   explicitly copy over later. This is what will become our final image.
FROM alpine:3.19
# This `RUN` command installs only the packages that are absolutely required to
# RUN the WordPress application.
#   - `php83-fpm`: The FastCGI Process Manager, which is the service that executes PHP code.
#   - `php83-mysqli`: The PHP extension needed to communicate with a MySQL/MariaDB database.
#   - `php83-phar`: ***(FIX)*** The extension needed to execute .phar files (like wp-cli).
#   - `mariadb-client`: ***(FIX)*** Provides command-line tools that wp-cli can use.
#   - `netcat-openbsd`: Provides the `nc` command used in `init.sh` to wait for the database.
#
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


RUN ln -s /usr/bin/php83 /usr/bin/php

# `COPY --from=builder ...`: This is the key to the multi-stage build.
#   - `--from=builder`: This special flag tells the `COPY` command to look in the previous
#     stage named `builder`, instead of the local build context.
#   - `/wp-cli.phar /usr/local/bin/wp`: It copies the `/wp-cli.phar` file that we downloaded
#     in the `builder` stage into the final image at `/usr/local/bin/wp`.
#
# THE RESULT: We get the `wp` tool in our final image WITHOUT the `wget` tool used to download it.
# This makes the final image smaller and more secure.
COPY --from=builder /wp-cli.phar /usr/local/bin/wp
# Make the wp-cli tool executable.
RUN chmod +x /usr/local/bin/wp
# Create the document root directory.
RUN mkdir -p /var/www/html
# Copy configuration and script files.
COPY conf/www.conf /etc/php83/php-fpm.d/www.conf
COPY conf/custom.ini /etc/php83/conf.d/custom.ini
COPY tools/init.sh /usr/local/bin/init.sh
# Set the correct file permissions for the configuration files (read-only for non-owners)
# and make the initialization script executable.
RUN chmod 644 /etc/php83/php-fpm.d/www.conf /etc/php83/conf.d/custom.ini && \
    chmod +x /usr/local/bin/init.sh
# `WORKDIR /var/www/html`: Sets the default working directory.
#   Any subsequent commands (`RUN`, `CMD`, `ENTRYPOINT`) will be executed from this
#   directory inside the container. This is important because your `init.sh` script
#   expects to be in this directory when it runs `wp core download`.
WORKDIR /var/www/html
# `EXPOSE 9000`: Documents that the PHP-FPM service inside the container listens on port 9000.
#   This does not publish the port; it's for informational purposes and for other containers.
# It's the Standard Convention: Just as port 443 is the standard for HTTPS,
# port 9000 is the universally recognized default port that the PHP-FPM (FastCGI Process Manager)
# service uses to listen for incoming requests from a web server like Nginx.
EXPOSE 9000
# Set the entrypoint.
ENTRYPOINT ["/usr/local/bin/init.sh"]