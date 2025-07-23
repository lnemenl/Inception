# Use the penultimate stable Alpine version
FROM alpine:3.20

# Install MariaDB and client
RUN apk update && apk add --no-cache mariadb mariadb-client && \
    rm -rf /var/cache/apk/*

# Create directories for data and socket
RUN mkdir -p /var/lib/mysql /run/mysqld && \
    chown -R mysql:mysql /var/lib/mysql /run/mysqld && \
    chmod 755 /run/mysqld

# Copy configuration and scripts
COPY conf/mariadb.cnf /etc/my.cnf
COPY tools/init.sh /usr/local/bin/init.sh
COPY healthcheck.sh /usr/local/bin/healthcheck.sh

# Set permissions
RUN chmod 644 /etc/my.cnf && \
    chmod 755 /usr/local/bin/init.sh /usr/local/bin/healthcheck.sh

# Expose MariaDB port
EXPOSE 3306

# Define healthcheck
HEALTHCHECK --interval=10s --timeout=5s --start-period=60s --retries=5 \
    CMD /usr/local/bin/healthcheck.sh

# Run initialization script
ENTRYPOINT ["/usr/local/bin/init.sh"]
