#!/bin/sh
# Inception Project: MariaDB Initialization Script

# Exit immediately if any command fails, ensuring a clean failure.
set -e

# --- Initialization Logic ---
# This block only runs if the database has not been initialized yet.
# It checks for the existence of the 'mysql' database directory, which is
# created during the initial installation process. This makes the script idempotent.
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "==> MariaDB data directory not found. Initializing database..."

    # Create necessary directories and set correct ownership.
    # The 'mysql' user must own these directories to be able to write data and runtime files.
    mkdir -p /var/lib/mysql /run/mysqld
    chown -R mysql:mysql /var/lib/mysql /run/mysqld
    chmod 777 /run/mysqld

    # Run the official MariaDB installation script.
    # --user=mysql ensures files are created with the correct owner.
    # --datadir points to our persistent volume location.
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql

    # Start MariaDB in the background temporarily to perform the initial setup.
    mysqld --user=mysql --datadir=/var/lib/mysql &
    pid="$!"

    # Wait for the server to become available.
    # This loop has a timeout to prevent it from running forever.
    timeout=30
    while ! mariadb-admin ping --socket=/run/mysqld/mysqld.sock -u root &> /dev/null; do
        timeout=$((timeout - 1))
        if [ $timeout -eq 0 ]; then
            echo "==> MariaDB startup failed." >&2
            exit 1
        fi
        echo "==> Waiting for MariaDB to start..."
        sleep 1
    done

    echo "==> MariaDB started. Performing initial security setup..."

    # Execute a series of SQL commands using a HERE document.
    # This is where we secure the root user and create the WordPress database and user
    # using the credentials passed via environment variables from the .env file.
    mariadb --socket=/run/mysqld/mysqld.sock -u root <<-EOF
        -- Set root password
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
        -- Create WordPress database
        CREATE DATABASE IF NOT EXISTS \`${WORDPRESS_DATABASE_NAME}\`;
        -- Create WordPress user and set password
        CREATE USER IF NOT EXISTS '${WORDPRESS_DATABASE_USER}'@'%' IDENTIFIED BY '${WORDPRESS_DATABASE_PASSWORD}';
        -- Grant all privileges on the WordPress database to the WordPress user
        GRANT ALL PRIVILEGES ON \`${WORDPRESS_DATABASE_NAME}\`.* TO '${WORDPRESS_DATABASE_USER}'@'%';
        -- Apply the changes
        FLUSH PRIVILEGES;
EOF

    # Stop the temporary server gracefully.
    if ! kill -s TERM "$pid" || ! wait "$pid"; then
        echo "==> Initial MariaDB process failed to stop." >&2
        exit 1
    fi
    echo "==> Initial setup complete."
fi

# --- Start Server ---
# On all subsequent runs, the script will skip the 'if' block and execute this command.
# `exec` replaces the current script process with the `mysqld` process.
# This is a critical best practice, as it makes `mysqld` the main process (PID 1)
# of the container, allowing it to receive signals from Docker correctly (e.g., on `docker stop`).
echo "==> Starting MariaDB server..."
exec mysqld --user=mysql --datadir=/var/lib/mysql