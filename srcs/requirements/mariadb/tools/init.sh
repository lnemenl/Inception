#!/bin/sh

# -----------------------------------------------------------------------------
# This script has two jobs:
# 1. On first launch, it initializes and secures the database.
# 2. On every launch, it starts the MariaDB server as the main process.
# -----------------------------------------------------------------------------

# Exit immediately if a command fails to prevent a broken setup.
set -e

# --- Read Passwords from Docker Secrets ---
# WHAT: Load passwords from files into shell variables.
# HOW:  Docker provides secrets as files. The environment variable holds the
#       path to the file, and 'cat' reads the content.
# WHY:  This is the secure way to handle credentials, preventing them from
#       being exposed in the container's environment or image layers.
if [ -n "$MYSQL_ROOT_PASSWORD_FILE" ]; then
    MYSQL_ROOT_PASSWORD=$(cat "$MYSQL_ROOT_PASSWORD_FILE")
fi
if [ -n "$WORDPRESS_DATABASE_PASSWORD_FILE" ]; then
    WORDPRESS_DATABASE_PASSWORD=$(cat "$WORDPRESS_DATABASE_PASSWORD_FILE")
fi

# Create the temporary directory for the MariaDB socket file.
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# --- First-Time Initialization ---
# This block runs ONLY if the database volume is empty. It checks for a core
# directory that MariaDB creates. This prevents wiping data on restart.
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "==> No database found. Starting initial setup..."

    # Create the basic MariaDB file structure and system tables.
    chown -R mysql:mysql /var/lib/mysql
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql

    # WHAT: Start a temporary MariaDB server in the background.
    # WHY:  To run SQL commands (like creating users), we need a live database
    #       connection. This temporary instance lets us configure everything
    #       before launching the final, permanent server.
    # HOW:  The '&' operator runs the process in the background. We save its
    #       Process ID ('$!') to a variable so we can stop it later.
    mysqld --user=mysql --datadir=/var/lib/mysql &
    pid="$!"

    # WHAT: Wait for the temporary server to be ready for connections.
    # WHY:  The server takes a moment to start. Attempting to connect
    #       instantly would fail. This loop ensures we only proceed when the
    #       database is fully operational.
    timeout=30
    while ! mariadb-admin ping --socket=/run/mysqld/mysqld.sock -u root &> /dev/null; do
        timeout=$((timeout - 1))
        if [ $timeout -eq 0 ]; then
            echo "==> MariaDB startup failed." >&2
            exit 1
        fi
        sleep 0.5
    done

    # --- Database Secure Installation and Setup ---
    # This 'heredoc' feeds a sequence of SQL commands directly to the mariadb
    # client to perform the initial setup.
    mariadb --socket=/run/mysqld/mysqld.sock -u root <<-EOF
        -- Set a password for the root user.
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
        -- Create the database for WordPress.
        CREATE DATABASE IF NOT EXISTS \`${WORDPRESS_DATABASE_NAME}\`;
        -- Create a dedicated user for WordPress. '%' allows connection from any host (i.e., the WordPress container).
        CREATE USER IF NOT EXISTS '${WORDPRESS_DATABASE_USER}'@'%' IDENTIFIED BY '${WORDPRESS_DATABASE_PASSWORD}';
        -- Grant that user all permissions on the WordPress database ONLY.
        GRANT ALL PRIVILEGES ON \`${WORDPRESS_DATABASE_NAME}\`.* TO '${WORDPRESS_DATABASE_USER}'@'%';
        -- Apply all the permission changes immediately.
        FLUSH PRIVILEGES;
EOF

    # WHAT: Stop the temporary server.
    # WHY:  We must shut down the temporary instance to free its resources
    #       (especially the network port) before the main server can start.
    # HOW:  'kill -s TERM' sends a graceful shutdown signal. 'wait' pauses the
    #       script until the process has completely finished, avoiding a race condition.
    kill -s TERM "$pid"
    wait "$pid"
    echo "==> Initial setup complete."
fi

# --- Start Main MariaDB Server ---
# WHAT: Start the final MariaDB server process.
# HOW:  'exec' replaces this script with the 'mysqld' command.
# WHY:  This makes 'mysqld' the main process (PID 1) of the container. This is
#       the correct way to run a service in Docker, as it allows Docker to
#       properly send system signals (like from 'docker stop') directly to the
#       service, ensuring a clean shutdown.
echo "==> Starting MariaDB server..."
exec mysqld --user=mysql --datadir=/var/lib/mysql