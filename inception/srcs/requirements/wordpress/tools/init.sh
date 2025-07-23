#!/bin/sh
set -e

echo "==> Waiting for MariaDB..."
while ! mariadb-admin ping --host=mariadb \
        --user="${WORDPRESS_DATABASE_USER}" \
        --password="${WORDPRESS_DATABASE_USER_PASSWORD}" --silent; do
    sleep 1
done

cd /var/www/html

# Install WP-CLI if missing
if [ ! -f /usr/local/bin/wp ]; then
    wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp
    chmod +x /usr/local/bin/wp
fi

# ✅ Only install if WordPress is not already installed
if ! wp core is-installed --allow-root; then
    echo "==> Installing WordPress..."
    wp core download --allow-root

    wp config create \
        --dbname="${WORDPRESS_DATABASE_NAME}" \
        --dbuser="${WORDPRESS_DATABASE_USER}" \
        --dbpass="${WORDPRESS_DATABASE_USER_PASSWORD}" \
        --dbhost="mariadb" \
        --allow-root

    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="${WORDPRESS_TITLE}" \
        --admin_user="${WORDPRESS_ADMIN}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    wp user create "${WORDPRESS_USER}" "${WORDPRESS_USER_EMAIL}" \
        --user_pass="${WORDPRESS_USER_PASSWORD}" \
        --role=editor \
        --allow-root
else
    echo "==> WordPress already installed. Skipping setup."
fi

echo "==> Starting PHP-FPM..."
exec php-fpm83 -F
