# Inception Project: MariaDB Service Dockerfile
# This Dockerfile builds the image for the MariaDB database server.

# Use a specific, stable version of Alpine Linux as the base image.
# Alpine is chosen for its small size, which results in a faster build
# and a more secure, minimal final image.
FROM alpine:3.20

# Install the MariaDB server and client packages.
# `apk add` is Alpine's package manager.
# `--no-cache` is a best practice that downloads the package index, installs
# the packages, and then discards the index, all in a single layer.
# This significantly reduces the image size.
# Switch to HTTP repositories, update, and install packages in a single layer.
RUN sed -i 's/https/http/g' /etc/apk/repositories && \
    apk update && \
    apk add --no-cache mariadb mariadb-client

# Copy the custom MariaDB configuration file into the image.
# This file will tell the server how to behave (e.g., where to store data).
COPY conf/mariadb.cnf /etc/my.cnf

# Copy the initialization script. This script will set up the database
# on the first run.
COPY tools/init.sh /usr/local/bin/init.sh

# Make the initialization script executable so that it can be run.
RUN chmod +x /usr/local/bin/init.sh

# Expose the default MariaDB port. This is for documentation and container linking.
# It doesn't publish the port to the host machine; the `docker-compose.yml` handles that.
EXPOSE 3306

# Set the entrypoint for the container. When the container starts, it will
# execute this script. The script is responsible for starting the MariaDB server.
ENTRYPOINT ["/usr/local/bin/init.sh"]
