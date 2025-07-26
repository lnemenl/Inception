#!/bin/bash
# This script automates the setup of the project's configuration.

ENV_FILE="srcs/.env"
SECRETS_DIR="srcs/secrets"

echo "🚀 Generating configuration files..."

# Create the secrets directory if it doesn't exist.
mkdir -p "$SECRETS_DIR"

# --- Create .env file for NON-SECRET configuration ---
DOMAIN_NAME="$(whoami).42.fr"

cat > "$ENV_FILE" << EOL
# --- Domain Configuration ---
DOMAIN_NAME=${DOMAIN_NAME}

# --- MariaDB Configuration ---
WORDPRESS_DATABASE_NAME=wordpress_db
WORDPRESS_DATABASE_USER=wp_user

# --- WordPress Configuration ---
WORDPRESS_TITLE=Inception Project
WORDPRESS_ADMIN_USER=wp_boss
WORDPRESS_ADMIN_EMAIL=boss@${DOMAIN_NAME}
WORDPRESS_USER=wp_user
WORDPRESS_USER_EMAIL=user@${DOMAIN_NAME}
EOL

# --- Create SECRET files for passwords ---
# The `tr -d` command removes any newline characters.
openssl rand -base64 12 | tr -d '\n' > "${SECRETS_DIR}/db_root_password.txt"
openssl rand -base64 12 | tr -d '\n' > "${SECRETS_DIR}/db_password.txt"
openssl rand -base64 12 | tr -d '\n' > "${SECRETS_DIR}/wp_admin_password.txt"
openssl rand -base64 12 | tr -d '\n' > "${SECRETS_DIR}/wp_user_password.txt"

echo "✅ Successfully created .env and secret files."