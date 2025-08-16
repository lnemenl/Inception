# -----------------------------------------------------------------------------
# This Dockerfile builds a minimal, custom MariaDB image. It installs the
# database server and sets up our custom configuration and initialization script.
# -----------------------------------------------------------------------------

# Use Alpine Linux as the base for a small and secure final image.
FROM alpine:3.19

# --- Install Packages ---
# WHAT FOR: To install the MariaDB server and the client tools. The client is
#           useful for the initialization script and for manual debugging.
#           The '--no-cache' flag reduces the final image size by discarding
#           the package cache after installation.
RUN sed -i 's/https/http/g' /etc/apk/repositories && \
    apk update && \
    apk add --no-cache mariadb mariadb-client

# Copy our custom MariaDB server configuration into the standard location
# within the image, overriding the default settings.
COPY conf/mariadb.cnf /etc/my.cnf

# Copy the initialization script that will set up and run the database.
COPY tools/init.sh /usr/local/bin/init.sh

# Make the initialization script executable.
RUN chmod +x /usr/local/bin/init.sh

# Document that the container exposes the standard MariaDB port. This is used
# for inter-container communication, not for exposing to the host.
EXPOSE 3306

# Set our custom script as the container's entrypoint. This script will handle
# the database initialization before starting the main server process.
ENTRYPOINT ["/usr/local/bin/init.sh"]