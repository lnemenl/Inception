#!/bin/sh
# -----------------------------------------------------------------------------
# This script is the entrypoint for the WordPress container. Its primary job
# is to fully automate the WordPress installation on the first run, and then
# start the PHP-FPM service on every run. This removes any need for manual
# setup.
# -----------------------------------------------------------------------------
set -e

# Securely read passwords from Docker secrets into shell variables.
if [ -n "$WORDPRESS_DATABASE_PASSWORD_FILE" ]; then
    WORDPRESS_DATABASE_PASSWORD=$(cat "$WORDPRESS_DATABASE_PASSWORD_FILE")
fi
if [ -n "$WORDPRESS_ADMIN_PASSWORD_FILE" ]; then
    WORDPRESS_ADMIN_PASSWORD=$(cat "$WORDPRESS_ADMIN_PASSWORD_FILE")
fi
if [ -n "$WORDPRESS_USER_PASSWORD_FILE" ]; then
    WORDPRESS_USER_PASSWORD=$(cat "$WORDPRESS_USER_PASSWORD_FILE")
fi

# --- Persistence Check ---
# WHAT FOR: To ensure the installation process runs only once. By checking for
#           the existence of 'wp-config.php' (a core WordPress file), we can
#           determine if this is a fresh start or a restart. This is the key
#           to data persistence, preventing our site from being wiped and
#           reinstalled every time the container is rebooted.
if [ ! -f "/var/www/html/wp-config.php" ]; then

    # --- Wait for Database ---
    # WHAT FOR: To prevent a race condition on startup. The WordPress container
    #           is often ready before the database container is. Attempting to
    #           connect to a database that isn't ready will cause this script
    #           to fail. This loop uses 'netcat' to repeatedly check if the
    #           MariaDB port is open, pausing the script until it gets a
    #           successful connection.
    echo "==> Waiting for MariaDB..."
    while ! nc -z mariadb 3306; do
        sleep 1
    done
    echo "==> MariaDB is ready."

    # --- Automated WordPress Installation via WP-CLI ---
    # WHAT FOR: To completely automate the entire WordPress setup process.
    #           WP-CLI is a powerful command-line tool that allows us to script
    #           every action we would normally do in the web-based installer,
    #           making the setup fast, repeatable, and non-interactive.
    echo "==> Configuring WordPress..."
    cd /var/www/html

    # Download the WordPress core files into the current directory.
    wp core download --allow-root
    # Generate the 'wp-config.php' file, connecting WordPress to the
    # database using the credentials passed as environment variables.
    wp config create \
        --dbname="${WORDPRESS_DATABASE_NAME}" \
        --dbuser="${WORDPRESS_DATABASE_USER}" \
        --dbpass="${WORDPRESS_DATABASE_PASSWORD}" \
        --dbhost="mariadb" \
        --allow-root
    # Run the main WordPress installer, creating the site and admin user.
    wp core install \
        --url="https://"${DOMAIN_NAME}"" \
        --title="${WORDPRESS_TITLE}" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root
    # Create a second, non-admin user as required by the project.
    wp user create "${WORDPRESS_USER}" "${WORDPRESS_USER_EMAIL}" \
        --role=editor \
        --user_pass="${WORDPRESS_USER_PASSWORD}" \
        --allow-root

    # --- Set File Permissions ---
    # WHAT FOR: This is a critical final step. The files were created by 'root'
    #           (the user running this script), but the PHP-FPM service runs
    #           as the unprivileged 'nobody' user. This command changes the
    #           ownership of all files to 'nobody', granting the web server
    #           the permissions it needs to manage them (e.g., for media uploads).
    chown -R nobody:nobody /var/www/html
fi

# --- Start Main PHP-FPM Service ---
# WHAT FOR: To launch the PHP engine that runs our WordPress site.
#
#   - 'exec': This is vital. It replaces this script's process with the 'php-fpm'
#     process, making it the main process (PID 1) of the container. This ensures
#     that Docker's stop signals are sent directly to PHP-FPM for a graceful shutdown.
#
#   - '-F' ('--nodaemonize'): This is mandatory. It forces PHP-FPM to run in the
#     foreground. Without it, the process would daemonize (go to the background),
#     this script would terminate, and Docker would shut the container down.
echo "==> Starting PHP-FPM..."
exec php-fpm83 -F