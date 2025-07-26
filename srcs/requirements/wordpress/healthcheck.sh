#!/bin/sh
# Inception Project: WordPress Healthcheck Script

# Use netcat (`nc`) to check if a process is listening on port 9000 on the
# local loopback interface (127.0.0.1).
# The `-z` flag tells netcat to scan for listening daemons without sending any data.
# If the port is open, the command returns exit code 0 (success).
# If it's closed, it returns 1 (failure), and Docker marks the container as unhealthy.
nc -z 127.0.0.1 9000