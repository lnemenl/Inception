#!/bin/bash
# -----------------------------------------------------------------------------
# This script automates the initial project setup. It's designed to be run
# only once by the Makefile to generate all necessary dynamic and secret
# configuration files.
# -----------------------------------------------------------------------------

# Exit immediately if any command fails to ensure a clean setup or none at all.
set -e

# --- Configuration Paths ---
SECRETS_DIR="secrets"
ENV_FILE="srcs/.env"
DATA_PATH="${HOME}/data"

echo "🚀 Generating dynamic and randomized configuration..."

# --- Generate Randomized Variables ---
# WHAT: Create unique names for the database and WordPress users.
# WHY:  Using randomized names instead of default values like 'wordpress' or
#       'admin' is a security best practice that makes the system harder
#       to guess for attackers.
WORDPRESS_DATABASE_NAME="db_$(openssl rand -hex 4)"
WORDPRESS_DATABASE_USER="user_$(openssl rand -hex 4)"
WORDPRESS_ADMIN_USER="gandalf$(openssl rand -hex 4)" # Avoids forbidden 'admin' usernames
WORDPRESS_USER="user_$(openssl rand -hex 4)"
LOGIN=$(whoami)
DOMAIN_NAME="${LOGIN}.42.fr"

# --- Create Data Directories on Host ---
# WHAT: Create the directories on the host machine for persistent data storage.
# WHY:  These directories must exist *before* Docker Compose tries to bind-mount
#       them as volumes. 'sudo' is used as they are created in the user's
#       home directory. 'chown' ensures the current user has ownership,
#       preventing Docker permission errors.
echo "🔑 You may be prompted for your password to create data directories."
sudo mkdir -p "${DATA_PATH}/mariadb"
sudo mkdir -p "${DATA_PATH}/wordpress"
sudo chown -R "$(whoami)" "${DATA_PATH}"

# Create the local directory to store secret files.
mkdir -p "$SECRETS_DIR"

# --- Create .env Configuration File ---
# WHAT: Generate the 'srcs/.env' file from a template.
# WHY:  This file provides non-sensitive configuration to Docker Compose. Using
#       a "here document" (heredoc) allows us to dynamically populate the
#       file with the randomized variables generated above.
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

# --- Create Secret Files for Passwords ---
# WHAT: Generate strong, random passwords and save each to a separate file.
# WHY:  These files are the source for the Docker Secrets. Storing each
#       password in its own file is a security best practice that limits
#       exposure.
# HOW:  'openssl rand -base64' creates a strong, random password. The output
#       is piped to 'tr -d '\n'' to remove any trailing newline characters,
#       ensuring the secret is a single, clean string.
openssl rand -base64 12 | tr -d '\n' > "${SECRETS_DIR}/db_root_password.txt"
openssl rand -base64 12 | tr -d '\n' > "${SECRETS_DIR}/db_password.txt"
openssl rand -base64 12 | tr -d '\n' > "${SECRETS_DIR}/wp_admin_password.txt"
openssl rand -base64 12 | tr -d '\n' > "${SECRETS_DIR}/wp_user_password.txt"

echo "✅ Successfully created fully randomized .env and secret files."