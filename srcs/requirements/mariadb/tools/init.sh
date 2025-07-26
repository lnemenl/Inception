#!/bin/sh
# Inception Project: MariaDB Initialization Script

set -e # Exit immediately if any command fails.

if [ -n "$MYSQL_ROOT_PASSWORD_FILE" ]; then
    MYSQL_ROOT_PASSWORD=$(cat "$MYSQL_ROOT_PASSWORD_FILE")
fi
if [ -n "$WORDPRESS_DATABASE_PASSWORD_FILE" ]; then
    WORDPRESS_DATABASE_PASSWORD=$(cat "$WORDPRESS_DATABASE_PASSWORD_FILE")
fi

# These commands MUST run every time the container starts.
# The /run/mysqld directory is temporary and is needed for the socket file.
# It is NOT part of the persistent volume.
echo "==> Ensuring runtime directory exists..."
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# This block only runs if the database has not been initialized yet.
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "==> MariaDB data directory not found. Initializing database..."

    # The data directory itself only needs its permissions set on the first run.
    chown -R mysql:mysql /var/lib/mysql

    # Run the official MariaDB installation script.
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql

    # Start MariaDB temporarily to perform the initial setup.
    mysqld --user=mysql --datadir=/var/lib/mysql &
    pid="$!"

    # Wait for the server to become available.
    timeout=30
    while ! mariadb-admin ping --socket=/run/mysqld/mysqld.sock -u root &> /dev/null; do
        timeout=$((timeout - 1))
        if [ $timeout -eq 0 ]; then
            echo "==> MariaDB startup failed." >&2
            exit 1
        fi
        sleep 0.5
    done

    echo "==> MariaDB started. Performing initial security setup..."

    # Secure the root user and create the WordPress database.
    mariadb --socket=/run/mysqld/mysqld.sock -u root <<-EOF
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
        CREATE DATABASE IF NOT EXISTS \`${WORDPRESS_DATABASE_NAME}\`;
        CREATE USER IF NOT EXISTS '${WORDPRESS_DATABASE_USER}'@'%' IDENTIFIED BY '${WORDPRESS_DATABASE_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${WORDPRESS_DATABASE_NAME}\`.* TO '${WORDPRESS_DATABASE_USER}'@'%';
        FLUSH PRIVILEGES;
EOF

    # Stop the temporary server gracefully.
    kill -s TERM "$pid"
    wait "$pid"
    echo "==> Initial setup complete."
fi

echo "==> Starting MariaDB server..."
# Use exec to make mysqld the main process (PID 1).
exec mysqld --user=mysql --datadir=/var/lib/mysql