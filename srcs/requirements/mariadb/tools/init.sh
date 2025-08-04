#!/bin/sh
#
# `#!/bin/sh` tells the system to execute this script
#   using the Bourne shell (`sh`).
# `set -e`: This command ensures that the script will exit immediately
#   if any command fails. It's a best practice for preventing unexpected behavior.
set -e
# This block reads the path to the secret file from an environment variable
# (passed by Docker Compose) and then reads the actual password from that file
# into a shell variable.
# `if [ -n "$VAR" ]`: Checks if the environment variable is not an empty string.
# `$(cat "$FILE")`: "Command substitution". It runs `cat` on the secret file
#   and the output (the password) is assigned to the variable.
#
if [ -n "$MYSQL_ROOT_PASSWORD_FILE" ]; then
    MYSQL_ROOT_PASSWORD=$(cat "$MYSQL_ROOT_PASSWORD_FILE")
fi
if [ -n "$WORDPRESS_DATABASE_PASSWORD_FILE" ]; then
    WORDPRESS_DATABASE_PASSWORD=$(cat "$WORDPRESS_DATABASE_PASSWORD_FILE")
fi

# The `/run/mysqld` directory is where the socket file will be created. This
# directory is temporary and not part of the persistent volume, so we must
# ensure it exists every time the container starts.

mkdir -p /run/mysqld
# gives the mysql user full ownership of the /run/mysqld directory and everything inside it. (user:group)
chown -R mysql:mysql /run/mysqld

# This `if` block is the core of the database's PERSISTENCE logic.
# It checks if the database has already been initialized by looking for a 'mysql'
# subdirectory inside the data directory.
# `[ ! -d "..." ]`: This is a test that returns true if the directory does NOT (`!`) exist (`-d`).
# The code inside this block will only run ONCE, the very first time the container
# starts with an empty volume.
#
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "==> MariaDB data directory not found. Initializing database..."

    # Change ownership of the main data directory to the `mysql` user.
    chown -R mysql:mysql /var/lib/mysql

    # `mariadb-install-db`: This is the official command to create the initial
    #   database file structure and system tables.
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql

    # Start the MariaDB server temporarily in the background (`&`) to perform setup.
    # By running the server in the background,
    # the script immediately gets control back and can proceed with the rest of its tasks while the server starts up.
    mysqld --user=mysql --datadir=/var/lib/mysql &
    # $!: This is a special, automatic variable in the shell.
    # Its value is always the PID of the most recently executed background command.
    #This line simply takes the PID from the special $! variable and saves it into a new, more clearly named variable called pid.
    # Why is the pid Needed?
    # The script needs to save the PID so it can specifically target and shut down this temporary server later.
    # After the setup queries are finished, the script needs to stop the temporary background server
    # before it starts the final, permanent one. The command to do this is kill.
    # However, kill needs to know the unique ID of the process it should stop.
    pid="$!"
    # Wait until the temporary server is ready to accept connections.
    # It pings the server via the socket file until it gets a successful response.
    #
    # `timeout=30`: This line initializes a shell variable named `timeout` with a starting
    #   value of 30. This will act as our countdown timer to prevent the script from
    #   waiting forever if the server fails to start.
    timeout=30
    # this line means: "While the `mariadb-admin ping` command is FAILING,
    # keep executing the loop." Once the ping succeeds, the loop will stop.
    #  > /dev/null means "take the output of this command and throw it away so it doesn't appear on the screen."
    while ! mariadb-admin ping --socket=/run/mysqld/mysqld.sock -u root &> /dev/null; do
        # `timeout=$((timeout - 1))`: This is shell arithmetic. It takes the current value
        #   of the `timeout` variable, subtracts 1, and assigns the new value back to it.
        #   This is the countdown step.
        timeout=$((timeout - 1))
        # `if [ $timeout -eq 0 ]; then ... fi`: This is the timeout check.
        #   - `[ $timeout -eq 0 ]`: This test checks if the `timeout` variable is equal (`-eq`) to 0.
        #   - If the condition is true, it means the server failed to start within the
        #     allotted number of attempts. The script then prints an error message...
        if [ $timeout -eq 0 ]; then
            echo "==> MariaDB startup failed." >&2
            # `exit 1`: ...and immediately exits with a status code of 1, which signifies
            #   an error. This will cause the container build or startup to fail.
            exit 1
        fi
        # `sleep 0.5`: This command pauses the script for half a second.
        #   - WHY: Without this pause, the `while` loop would run hundreds of times per second,
        #     consuming a lot of CPU. This makes the loop "polite" by only checking the server's
        #     status twice per second, which is more than enough.
        sleep 0.5
    done

    echo "==> MariaDB started. Performing initial security setup..."
    # `mariadb ... <<-EOF`: This is a "here document" (heredoc). It's a way to feed
    #   multi-line text directly into a command's input without needing a separate file.
    #   - `mariadb`: The command-line client program used to send queries to the MariaDB server.
    #   - `--socket=...`: This flag tells the client to connect using the fast and efficient
    #     Unix socket file, as the server is running on the same "machine" (the container).
    #   - `-u root`: The `-u` (user) flag specifies to connect as the `root` database user,
    #     which has the necessary permissions to create other users and databases.
    #   - `<<-EOF`: This starts the heredoc. It tells the shell: "Treat all the following lines
    #     as the input for the `mariadb` command, until you see a line that contains only `EOF`."
    #     The `-` in `<<-` is a special feature that strips leading tab characters, allowing for
    #     cleaner indentation in the script.

    # This is a sequence of SQL (Structured Query Language) commands that will be
    # executed by the MariaDB server. Each command ends with a semicolon `;`.
    # Inside this block, shell variables like `${VAR}` are expanded before the text
    # is sent to the `mariadb` command.

    # `ALTER USER`: The SQL command to modify an existing user.
    # `'root'@'localhost'`: Specifies the `root` user when connecting from the local machine.
    # `IDENTIFIED BY ...`: This clause sets the user's password.
    # `${MYSQL_ROOT_PASSWORD}`: The shell replaces this with the random password

    # `CREATE DATABASE`: The SQL command to create a new, empty database.
    # `IF NOT EXISTS`: A safety clause. The command only runs if a database with this
    #   name doesn't already exist, preventing errors.
    # `` (backticks): In SQL, backticks are used to quote identifiers (like database or
    #   table names), which is a good practice.
    # `${WORDPRESS_DATABASE_NAME}`: The shell expands this to the random database name.

    # `CREATE USER`: The SQL command to create a new user account.
    # `'@'%'`: This is an important security setting. The `%` is a wildcard that means this
    #   user is allowed to connect from *any* IP address. This is necessary so the WordPress
    #   container (which is on the same network but is a different "machine") can connect.

    # `GRANT ALL PRIVILEGES`: This command gives a user permissions.
    # `ON \`...\`.*`: This specifies *what* the permissions apply to. In this case, it means
    #   "on all tables (`*`) inside the specified WordPress database".
    # `TO '...'`: Specifies which user is receiving these permissions.

    # `FLUSH PRIVILEGES;`: This command tells the MariaDB server to reload its internal
    #   permission tables from disk. This ensures that all the user and permission
    #   changes we just made take effect immediately without needing a server restart.

    mariadb --socket=/run/mysqld/mysqld.sock -u root <<-EOF
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
        CREATE DATABASE IF NOT EXISTS \`${WORDPRESS_DATABASE_NAME}\`;
        CREATE USER IF NOT EXISTS '${WORDPRESS_DATABASE_USER}'@'%' IDENTIFIED BY '${WORDPRESS_DATABASE_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${WORDPRESS_DATABASE_NAME}\`.* TO '${WORDPRESS_DATABASE_USER}'@'%';
        FLUSH PRIVILEGES;
EOF

    # Gracefully shut down the temporary server.
    # `kill`: This is a standard shell command used to send a "signal" to a process,
    #   usually to request its termination.
    #
    # `-s TERM`: This flag specifies which signal to send. `TERM` (short for SIGTERM) is
    #   the standard termination signal. It's a "polite" request, asking the program
    #   to shut down gracefully. This gives the MariaDB server a chance to finish its
    #   current tasks, flush any data to disk, and clean up before exiting. This is
    #   the correct way to stop a database to prevent data corruption.
    #   (An alternative, `kill -s KILL` or `kill -9`, is a forceful, "impolite" signal
    #   that terminates the process immediately and should be avoided unless necessary).
    #
    # `"$pid"`: This is the target of the `kill` command. The shell expands this to the
    #   Process ID (PID) of the temporary background server that we saved earlier. This
    #   ensures we are stopping the correct process.
    kill -s TERM "$pid"

    # `wait`: This is a shell built-in command that pauses the execution of the script.
    #
    # `"$pid"`: It waits specifically for the process with this PID to completely finish
    #   and exit.
    #
    # WHY IT'S NEEDED: The `kill` command sends the stop signal and then immediately
    #   returns, allowing the script to continue. However, the MariaDB server might take a
    #   moment to shut down. `wait "$pid"` forces the script to pause and wait until the
    #   temporary server is completely gone. This prevents a "race condition" where the
    #   script might try to start the final server before the temporary one has finished shutting down.
    wait "$pid"
    echo "==> Initial setup complete."
fi

echo "==> Starting MariaDB server..."
#
# `exec`: This is a crucial command for Docker. It REPLACES the current shell
#   script process with the `mysqld` process.
# This makes `mysqld` the main process (PID 1) of the container, allowing Docker
# to correctly manage its lifecycle (e.g., sending stop signals).
# This is the correct way to start a service and avoids the forbidden "hacky patches".
#
exec mysqld --user=mysql --datadir=/var/lib/mysql