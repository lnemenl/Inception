# -----------------------------------------------------------------------------
# This Makefile provides a convenient command interface for managing the
# lifecycle of the Docker Compose application.
# -----------------------------------------------------------------------------

# Dynamically set the Docker Compose project name to the lowercase name of the
# current directory. This ensures that containers, networks, and volumes for
# this project are grouped together and avoids conflicts with other projects.
PROJECT_NAME = $(shell basename $(PWD) | tr '[:upper:]' '[:lower:]')

# --- Main Commands ---

# The default command, executed when running 'make'.
# Builds all images and starts the services in detached mode.
all: setup
	@echo "--- Starting Inception services... ---"
	@docker-compose -f srcs/docker-compose.yml --project-name $(PROJECT_NAME) up -d --build
	@echo "\n🎉 Inception is ready!"
	# This block extracts key details from the .env and secrets files to print a
	# helpful summary with the website URL and login credentials.
	@DOMAIN=$$(grep 'DOMAIN_NAME' srcs/.env | cut -d= -f2); \
	ADMIN_USER=$$(grep 'WORDPRESS_ADMIN_USER' srcs/.env | cut -d= -f2); \
	PASS=$$(cat secrets/wp_admin_password.txt); \
	echo "------------------------------------------------------------------"; \
	echo "Access Details:"; \
	echo "  - Website URL.........: https://$$DOMAIN"; \
	echo "  - WordPress Admin.....: https://$$DOMAIN/wp-admin"; \
	echo "  - Admin Username......: $$ADMIN_USER"; \
	echo "  - Admin Password......: $$PASS"; \
	echo "------------------------------------------------------------------";

# --- Lifecycle Commands ---

# Rebuilds the Docker images without starting the containers.
build: setup
	@echo "--- Building Docker images... ---"
	@docker-compose -f srcs/docker-compose.yml --project-name $(PROJECT_NAME) build

# Starts the services without forcing a rebuild.
up: setup
	@echo "--- Starting services... ---"
	@docker-compose -f srcs/docker-compose.yml --project-name $(PROJECT_NAME) up -d

# Stops and removes the project's containers and network.
# The '-' prefix ignores errors if the containers are already stopped.
down:
	@echo "--- Stopping services... ---"
	-@docker-compose -f srcs/docker-compose.yml --project-name $(PROJECT_NAME) down

# Stops and removes containers, networks, and any orphaned containers.
clean:
	@echo "--- Removing containers and networks... ---"
	-@docker-compose -f srcs/docker-compose.yml --project-name $(PROJECT_NAME) down --remove-orphans

# WARNING: Destructive. Removes everything: containers, networks, volumes (all data),
# and the generated secrets and .env file.
fclean: clean
	@echo "--- Deleting all data and configuration... ---"
	-@sudo rm -rf "$(HOME)/data"
	-@sudo rm -rf secrets
	-@rm -f srcs/.env
	@echo "✅ Project completely cleaned."

# A shortcut to fully clean and rebuild the entire project from scratch.
re: fclean all

# --- Information & Debugging ---

# Shows the status of all project containers (running or stopped).
status:
	@echo "--- Container Status ---"
	@docker-compose -f srcs/docker-compose.yml --project-name $(PROJECT_NAME) ps -a

# Streams the logs from all running containers in real-time. (Ctrl+C to exit)
logs:
	@echo "--- Tailing Logs (Ctrl+C to exit) ---"
	@docker-compose -f srcs/docker-compose.yml --project-name $(PROJECT_NAME) logs -f

# --- Helper Targets ---

# An internal target that runs the one-time setup script.
# It only runs if the 'srcs/.env' file does not already exist.
setup:
	@if [ ! -f srcs/.env ]; then \
		echo "--- Running first-time setup... ---"; \
		/bin/sh setup.sh; \
	fi

# Displays a list of available commands.
help:
	@echo "Available 'make' commands:"
	@echo "  all       Builds and starts all services (default)."
	@echo "  up        Starts services without forcing a build."
	@echo "  down      Stops and removes the containers."
	@echo "  re        Rebuilds the project from scratch."
	@echo "  status    Shows the status of all services."
	@echo "  logs      Tails the logs from all running containers."
	@echo "  clean     Removes containers and networks."
	@echo "  fclean    Removes everything, including data and secrets."
	@echo "  help      Shows this help message."

# Declares targets as "phony", meaning they are commands, not files.
# This prevents conflicts with files of the same name and improves performance.
.PHONY: all build up down clean fclean re status logs setup help