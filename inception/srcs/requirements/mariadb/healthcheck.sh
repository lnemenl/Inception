#!/bin/sh
# Check if MariaDB is responsive via socket
#!/bin/sh
exec /usr/bin/mariadb-admin ping --socket=/run/mysqld/mysqld.sock -u root -p"$MYSQL_ROOT_PASSWORD" --silent
exit $?
