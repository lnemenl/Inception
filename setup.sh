#!/bin/bash
# This script automates the creation of the .env file for the Inception project.
# It ensures portability and security by generating necessary variables on the fly.

# Define the path to the .env file relative to the project root.
ENV_FILE="srcs/.env"

# --- Main Setup Function ---
# This function handles the entire logic of creating the .env file.
setup_environment() {
    # The Makefile already checks if the file exists, but this is a good safeguard.
    if [ -f "$ENV_FILE" ]; then
        echo "✅ .env file already exists. Skipping generation."
        return
    fi

    echo "🚀 Generating new .env file with secure, random credentials..."

    # 1. DOMAIN NAME: Make the project portable.
    # The subject requires the domain to be 'login.42.fr'.
    # Using `whoami` gets the current user's login automatically, so the project
    # works on any machine without manual changes.
    DOMAIN_NAME="$(whoami).42.fr"

    # 2. PASSWORDS: Never hardcode credentials.
    # Generate strong, random passwords using OpenSSL. This is much more secure
    # than using simple or default passwords.
    MYSQL_ROOT_PASSWORD=$(openssl rand -base64 12)
    WORDPRESS_DB_PASSWORD=$(openssl rand -base64 12)
    WORDPRESS_ADMIN_PASSWORD=$(openssl rand -base64 12)
    WORDPRESS_USER_PASSWORD=$(openssl rand -base64 12)

    # 3. FILE CREATION: Write the configuration.
    # A HERE document (<< EOL ... EOL) is a clean way to write a multi-line string
    # to a file. It's more readable than multiple `echo` statements.
    cat > "$ENV_FILE" << EOL
# --- Domain Configuration ---
DOMAIN_NAME=${DOMAIN_NAME}

# --- MariaDB Credentials (Generated Randomly) ---
# This is the root password for the database.
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}

# These are the credentials for the WordPress database and user.
WORDPRESS_DATABASE_NAME=wordpress_db
WORDPRESS_DATABASE_USER=wp_user
WORDPRESS_DATABASE_PASSWORD=${WORDPRESS_DB_PASSWORD}

# --- WordPress Credentials (Generated Randomly) ---
WORDPRESS_TITLE=Inception Project

# The admin username must not contain 'admin' or 'administrator'.
WORDPRESS_ADMIN_USER=wp_boss
WORDPRESS_ADMIN_PASSWORD=${WORDPRESS_ADMIN_PASSWORD}
WORDPRESS_ADMIN_EMAIL=boss@${DOMAIN_NAME}

# The project requires at least two users in the database.
WORDPRESS_USER=wp_user
WORDPRESS_USER_PASSWORD=${WORDPRESS_USER_PASSWORD}
WORDPRESS_USER_EMAIL=user@${DOMAIN_NAME}
EOL

    echo "✅ Successfully created .env file."
}

# --- Script Entrypoint ---
# This calls the main function to run the setup logic.
setup_environment