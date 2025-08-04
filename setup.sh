# This tells the system to execute this script using the bash shell.
#!/bin/bash

# `set -e` is a shell command that ensures the script will exit immediately
# if any command fails (exits with a non-zero status). This is a best practice
# for preventing unexpected behavior from partial script execution.
#
set -e

SECRETS_DIR="secrets"
ENV_FILE="srcs/.env"

# `${HOME}` is a standard environment variable that automatically expands
# to the current user's home directory (e.g., /home/user or /Users/user).
#
DATA_PATH="${HOME}/data"

echo "🚀 Generating dynamic and randomized configuration..."

# This is a shell variable assignment using "command substitution" `$(...)`.
# The shell first executes the command inside the parentheses and then assigns its output
# to the variable.
# `openssl rand`: A command to generate cryptographically strong random bytes.
# `-hex 4`: Specifies the output format as hexadecimal. `4` means 4 bytes, which
#   results in 8 hexadecimal characters (e.g., a1b2c3d4).
#
WORDPRESS_DATABASE_NAME="db_$(openssl rand -hex 4)"
WORDPRESS_DATABASE_USER="user_$(openssl rand -hex 4)"
WORDPRESS_ADMIN_USER="gandalf$(openssl rand -hex 4)"
WORDPRESS_USER="user_$(openssl rand -hex 4)"

LOGIN=$(whoami)
DOMAIN_NAME="${LOGIN}.42.fr"

# --- Create Data Directories ---
echo "🔑 You may be prompted for your password to create data directories."
# `mkdir -p`: The `mkdir` command creates a directory. The `-p` flag tells it to create
#   parent directories as needed and not to show an error if the directory already exists.
sudo mkdir -p "${DATA_PATH}/mariadb"
sudo mkdir -p "${DATA_PATH}/wordpress"
#
# `chown -R`: The `chown` command changes the owner of files and directories. The `-R` (recursive)
#   flag makes it apply to the directory and everything inside it.
# `$(whoami)`: This ensures the newly created directories are owned by the current user,
#   which is crucial for preventing permission errors with Docker.
sudo chown -R "$(whoami)" "${DATA_PATH}"
# --- Create secrets directory ---
mkdir -p "$SECRETS_DIR"
# --- Create .env File from Scratch ---
# `cat > "$ENV_FILE" << EOL`: This is a "here document" (heredoc).
# `cat > "$ENV_FILE"`: This tells the `cat` command to write its input into the file specified by `$ENV_FILE`.
# `<< EOL`: This tells the shell to treat all the following lines as the input to the `cat` command,
#   until it finds a line containing only `EOL` (End Of Line).
# Inside the heredoc, variables like `${DOMAIN_NAME}` are expanded by the shell to their actual values.
cat > "$ENV_FILE" << EOL
# Inception Project Environment Configuration
# Generated on $(date)

# --- Domain & Path Configuration ---
DOMAIN_NAME=${DOMAIN_NAME}
DATA_PATH=${DATA_PATH}

# --- MariaDB Configuration (Randomized) ---
WORDPRESS_DATABASE_NAME=${WORDPRESS_DATABASE_NAME}
WORDPRESS_DATABASE_USER=${WORDPRESS_DATABASE_USER}

# --- WordPress Configuration (Randomized) ---
WORDPRESS_TITLE=Inception by ${LOGIN}
WORDPRESS_ADMIN_USER=${WORDPRESS_ADMIN_USER}
WORDPRESS_ADMIN_EMAIL=${WORDPRESS_ADMIN_USER}@${DOMAIN_NAME}
WORDPRESS_USER=${WORDPRESS_USER}
WORDPRESS_USER_EMAIL=${WORDPRESS_USER}@${DOMAIN_NAME}
EOL

# --- Create SECRET files for passwords ---
# This line generates a random password and writes it to a file.
# `openssl rand -base64 12`: Generates 12 random bytes and encodes them using Base64,
#   which is a good format for passwords as it includes uppercase, lowercase, and numbers.
# `|`: The pipe operator sends the output of the `openssl` command as the input to the `tr` command.
# `tr -d '\n'`: The `tr` command deletes (`-d`) all newline characters (`\n`), ensuring the password
#   is a single line.
# `>`: The redirect operator. It writes the final output (the password) into the specified file.
#
openssl rand -base64 12 | tr -d '\n' > "${SECRETS_DIR}/db_root_password.txt"
openssl rand -base64 12 | tr -d '\n' > "${SECRETS_DIR}/db_password.txt"
openssl rand -base64 12 | tr -d '\n' > "${SECRETS_DIR}/wp_admin_password.txt"
openssl rand -base64 12 | tr -d '\n' > "${SECRETS_DIR}/wp_user_password.txt"

echo "✅ Successfully created fully randomized .env and secret files."