#!/bin/bash
# This script automates the setup of the project's configuration.

SECRETS_DIR="srcs/secrets"

echo "🚀 Generating configuration files..."

# Create the secrets directory if it doesn't exist.
mkdir -p "$SECRETS_DIR"

# Create data folder for volumes
mkdir -p "$HOME/data/mariadb" "$HOME/data/wordpress"

# --- Create .env file for NON-SECRET configuration ---
cp ../.env srcs/

# --- Create SECRET files for passwords ---
# The `tr -d` command removes any newline characters.
openssl rand -base64 12 | tr -d '\n' > "${SECRETS_DIR}/db_root_password.txt"
openssl rand -base64 12 | tr -d '\n' > "${SECRETS_DIR}/db_password.txt"
openssl rand -base64 12 | tr -d '\n' > "${SECRETS_DIR}/wp_admin_password.txt"
openssl rand -base64 12 | tr -d '\n' > "${SECRETS_DIR}/wp_user_password.txt"

echo "✅ Successfully created .env and secret files."
