#!/bin/sh
set -e

if [ -n "$WORDPRESS_DATABASE_PASSWORD_FILE" ]; then
    WORDPRESS_DATABASE_PASSWORD=$(cat "$WORDPRESS_DATABASE_PASSWORD_FILE")
fi
if [ -n "$WORDPRESS_ADMIN_PASSWORD_FILE" ]; then
    WORDPRESS_ADMIN_PASSWORD=$(cat "$WORDPRESS_ADMIN_PASSWORD_FILE")
fi
if [ -n "$WORDPRESS_USER_PASSWORD_FILE" ]; then
    WORDPRESS_USER_PASSWORD=$(cat "$WORDPRESS_USER_PASSWORD_FILE")
fi

# This script only runs the first time the container starts.
if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "==> Waiting for MariaDB..."
    # Use `nc` for a simple, reliable wait.
    while ! nc -z mariadb 3306; do
        sleep 1
    done
    echo "==> MariaDB is ready."

    echo "==> Configuring WordPress..."
    cd /var/www/html
    wp core download --allow-root
    wp config create \
        --dbname="${WORDPRESS_DATABASE_NAME}" \
        --dbuser="${WORDPRESS_DATABASE_USER}" \
        --dbpass="${WORDPRESS_DATABASE_PASSWORD}" \
        --dbhost="mariadb" \
        --allow-root

    # The installation can take a moment, let's wait before starting FPM.
    echo "==> Installing WordPress..."
    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="${WORDPRESS_TITLE}" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    wp user create "${WORDPRESS_USER}" "${WORDPRESS_USER_EMAIL}" \
        --role=editor \
        --user_pass="${WORDPRESS_USER_PASSWORD}" \
        --allow-root

    # Set ownership after all files are in place.
    chown -R nobody:nobody /var/www/html
fi

echo "==> Starting PHP-FPM..."
# Use exec to make php-fpm the main process.
exec php-fpm83 -F