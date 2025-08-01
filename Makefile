# Inception Project Makefile
# This file is the main entry point for building, running, and managing the project.
# It simplifies the Docker Compose commands into easy-to-use targets.

# Use the project's directory name as the default project name for Docker Compose.
# This ensures all containers, networks, and volumes are grouped under a unique name,
# preventing conflicts with other Docker projects.
PROJECT_NAME = $(shell basename $(PWD) | tr '[:upper:]' '[:lower:]')

# --- Core Targets ---

# The default target that runs when you just type `make`.
# It ensures the environment is set up and then builds and starts all services.
# The -d flag runs the containers in detached mode (in the background).
all: setup
	@echo "🚀 Building and starting Inception services..."
	@docker-compose -f srcs/docker-compose.yml --project-name $(PROJECT_NAME) up --build -d

# Add setup as a dependency here
build: setup
	@echo "🔧 Building Docker images..."
	@docker-compose -f srcs/docker-compose.yml --project-name $(PROJECT_NAME) build

# Add setup as a dependency here
up: setup
	@echo "🚀 Launching containers..."
	@docker-compose -f srcs/docker-compose.yml --project-name $(PROJECT_NAME) up -d

# Stops the running containers but does not remove them.
down:
	@echo "🛑 Stopping containers..."
	@docker-compose -f srcs/docker-compose.yml --project-name $(PROJECT_NAME) down

# Rebuilds and restarts the entire project from scratch.
# This is a convenient combination of `fclean` and `all`.
re: fclean all

# --- Management & Cleanup Targets ---

# Displays the real-time logs from all running containers.
# Very useful for debugging.
logs:
	@echo "📜 Tailing container logs..."
	@docker-compose -f srcs/docker-compose.yml --project-name $(PROJECT_NAME) logs -f

# Shows the status of all containers in the project (Up, Down, Healthy, etc.).
status:
	@echo "📊 Checking container status..."
	@docker-compose -f srcs/docker-compose.yml --project-name $(PROJECT_NAME) ps -a

# Stops and removes the containers. Networks are also removed.
# Volumes are NOT removed by this command, preserving the data.
clean:
	@echo "🧹 Stopping and removing containers and networks..."
	@docker-compose -f srcs/docker-compose.yml --project-name $(PROJECT_NAME) down --remove-orphans

# The "full clean" command. It does everything `clean` does, but also
# deletes the volumes (where database and WordPress files are stored)
# and removes the auto-generated .env file.
# Use this to reset the project to its initial state.
fclean:
	@echo "🗑️ Removing all containers, networks, volumes, and .env file..."
	-@docker-compose -f srcs/docker-compose.yml --project-name $(PROJECT_NAME) down -v --remove-orphans
	@rm -f srcs/.env
	@sudo  rm -rf srcs/secrets ../data
	@echo "✅ Project completely cleaned."

# --- Helper Targets ---

# This target is a prerequisite for most other targets.
# It runs the setup script to ensure the .env file exists.
setup:
	@# This check prevents the setup script from running if the .env file already exists.
	@if [ ! -f srcs/.env ]; then \
		/bin/sh setup.sh; \
	fi


help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all       Builds and starts all services (default)."
	@echo "  build     Builds the Docker images."
	@echo "  up        Starts the services."
	@echo "  down      Stops the services."
	@echo "  re        Rebuilds and restarts the entire project."
	@echo "  logs      Tails the logs from all services."
	@echo "  status    Shows the status of all services."
	@echo "  clean     Stops and removes containers."
	@echo "  fclean    Removes all containers, networks, volumes, and the .env file."
	@echo "  help      Shows this help message."

# .PHONY tells Make that these are not actual files.
# This prevents Make from getting confused if a file with the same name exists,
# and it can help with performance.
.PHONY: all build up down re logs status clean fclean setup help
