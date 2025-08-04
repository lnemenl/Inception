#!/bin/sh
set -e

# Read the passwords from the secret files into shell variables.
if [ -n "$WORDPRESS_DATABASE_PASSWORD_FILE" ]; then
    WORDPRESS_DATABASE_PASSWORD=$(cat "$WORDPRESS_DATABASE_PASSWORD_FILE")
fi
if [ -n "$WORDPRESS_ADMIN_PASSWORD_FILE" ]; then
    WORDPRESS_ADMIN_PASSWORD=$(cat "$WORDPRESS_ADMIN_PASSWORD_FILE")
fi
if [ -n "$WORDPRESS_USER_PASSWORD_FILE" ]; then
    WORDPRESS_USER_PASSWORD=$(cat "$WORDPRESS_USER_PASSWORD_FILE")
fi

# This is the PERSISTENCE check for WordPress. It checks if the `wp-config.php` file
# already exists. If it does, it means WordPress is already installed, and the
# entire installation block is skipped. This only runs on the first start.
if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "==> Waiting for MariaDB..."
    #
    # This `while` loop is a simple and effective way to wait for the database.
    # `nc -z mariadb 3306`: The `nc` (netcat) command tries to establish a connection
    #   to the hostname `mariadb` on port `3306`. The `-z` flag makes it scan
    #   without sending any data. The command succeeds (exit code 0) only when the
    #   database is ready to accept connections.
    #
    while ! nc -z mariadb 3306; do
        sleep 1
    done
    echo "==> MariaDB is ready."

    echo "==> Configuring WordPress..."
    cd /var/www/html

    # These are `wp-cli` commands. `wp-cli` is a powerful command-line tool for
    # managing WordPress installations.
    # `--allow-root`: This flag is required because we are running this script as
    #   the root user inside the container.
    # Download the WordPress core files.
    wp core download --allow-root
    # Create the `wp-config.php` file using the database credentials from the .env file.
    wp config create \
        --dbname="${WORDPRESS_DATABASE_NAME}" \
        --dbuser="${WORDPRESS_DATABASE_USER}" \
        --dbpass="${WORDPRESS_DATABASE_PASSWORD}" \
        --dbhost="mariadb" \
        --allow-root

    echo "==> Installing WordPress..."
    # Run the main WordPress installation process.
    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="${WORDPRESS_TITLE}" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    # Create the second user as required by the subject.
    wp user create "${WORDPRESS_USER}" "${WORDPRESS_USER_EMAIL}" \
        --role=editor \
        --user_pass="${WORDPRESS_USER_PASSWORD}" \
        --allow-root

    # Set the correct ownership for all the created files so the web server can use them.
    chown -R nobody:nobody /var/www/html
fi

echo "==> Starting PHP-FPM..."
# Use `exec` to make `php-fpm` the main process (PID 1).
# `php-fpm83 -F`: The `-F` (`--nodaemonize`) flag is crucial. It tells PHP-FPM
#   to run in the FOREGROUND, which is required by Docker.
exec php-fpm83 -F