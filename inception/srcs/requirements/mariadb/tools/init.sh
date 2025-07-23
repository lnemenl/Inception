#!/bin/sh
set -e

# Ensure directories exist and have correct permissions
mkdir -p /run/mysqld
chown -R mysql:mysql /var/lib/mysql /run/mysqld
chmod 755 /run/mysqld

# Initialize database if not already set up
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "==> Initializing MariaDB..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db >/dev/null

    echo "==> Starting MariaDB temporarily..."
    mysqld --user=mysql --socket=/run/mysqld/mysqld.sock --skip-networking=0 &

    # Wait for MariaDB to be ready
    for i in $(seq 1 30); do
        if mariadb-admin ping --socket=/run/mysqld/mysqld.sock --silent; then
            break
        fi
        sleep 1
    done

    echo "==> Creating WordPress DB and user..."
    mariadb --socket=/run/mysqld/mysqld.sock -u root <<EOF
FLUSH PRIVILEGES;
#ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${WORDPRESS_DATABASE_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${WORDPRESS_DATABASE_USER}'@'%' IDENTIFIED BY '${WORDPRESS_DATABASE_USER_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${WORDPRESS_DATABASE_NAME}\`.* TO '${WORDPRESS_DATABASE_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    # Shutdown temporary server
    mariadb-admin --socket=/run/mysqld/mysqld.sock shutdown
fi

echo "==> Starting MariaDB..."
exec mysqld --user=mysql
