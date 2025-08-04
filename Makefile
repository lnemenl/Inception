#
# `PROJECT_NAME` is a 'make' variable that will hold the name of the project.
# `=` is the assignment operator.
# `$(shell ...)` is a 'make' function that executes a command in the system's shell
# and substitutes the output back into the Makefile.
# `PWD` is a default variable that contains the path to the current working directory.
# `basename` is a standard shell command that strips the directory path, leaving only the final component
# (e.g., /home/user/Inception -> Inception).
# `|` is the "pipe" operator in the shell. It sends the output of the command on its left
# as the input to the command on its right.
# `tr '[:upper:]' '[:lower:]'` is the 'translate' shell command. It takes the input from the pipe
# and translates all uppercase characters to their lowercase equivalents, as Docker prefers.
#
PROJECT_NAME = $(shell basename $(PWD) | tr '[:upper:]' '[:lower:]')

# `all` is the default target that runs when you just type `make`.
# `setup` is a dependency. This means 'make' will run the 'setup' target first.
#
all: setup
# `@` is a 'make' directive. It prevents the command itself from being printed to the terminal,
# so you only see the output of the command.
	@echo "--- Starting Inception services... ---"
#
# `docker-compose` is the command-line tool for managing multi-container Docker applications.
# `-f srcs/docker-compose.yml`: The '-f' (file) flag specifies the path to the Compose configuration file.
# `--project-name $(PROJECT_NAME)`: Explicitly sets a name for this project. Docker Compose uses this
#   name as a prefix for all created resources (containers, networks, volumes) to avoid conflicts.
#   `$(PROJECT_NAME)` is expanded by 'make' to the value we defined at the top.
# `up`: The primary command to create and start containers. It will build images if they don't exist.
# `-d`: The '-d' (detached) flag runs the containers in the background.
#
	@docker-compose -f srcs/docker-compose.yml --project-name $(PROJECT_NAME) up -d
	@echo "\n🎉 Inception is ready!"
#
# This entire block is a single, multi-line shell command.
# `@` at the start applies to the whole block. `\` at the end of a line continues the command.
# `DOMAIN=...;`: This is a shell variable assignment. The semicolon separates commands.
# `$$`: A double dollar sign is required to pass a literal `$` to the shell,
#   as 'make' uses a single `$` for its own variables.
# `$$(grep ...)`: This is "command substitution" in the shell. The shell runs the command
#   inside the parentheses and substitutes its output.
# `grep 'DOMAIN_NAME' srcs/.env`: Searches for the line containing 'DOMAIN_NAME' in the .env file.
# `cut -d= -f2`: The output of `grep` is piped to `cut`. `cut` extracts sections from lines.
#   `-d=` sets the delimiter to '=', and `-f2` selects the second field (the value).
# `PASS=$$(cat ...)`: The `cat` command reads the content of the password file, and command substitution
#   assigns that content to the shell variable `PASS`.
#
	@DOMAIN=$$(grep 'DOMAIN_NAME' srcs/.env | cut -d= -f2); \
	ADMIN_USER=$$(grep 'WORDPRESS_ADMIN_USER' srcs/.env | cut -d= -f2); \
	PASS=$$(cat secrets/wp_admin_password.txt); \
	echo "------------------------------------------------------------------"; \
	echo "Access Details"; \
	echo "  - Website URL.........: https://$$DOMAIN"; \
	echo "  - WordPress Admin.....: https://$$DOMAIN/wp-admin"; \
	echo "  - Admin Username......: $$ADMIN_USER"; \
	echo "  - Admin Password......: $$PASS"; \
	echo ""; \
	echo "------------------------------------------------------------------"; \
	#
	@echo "Available 'make' commands:"; \
	echo "  all       Builds and starts all services (default)."; \
	echo "  up        Starts services without forcing a build."; \
	echo "  down      Stops and removes the containers."; \
	echo "  re        Rebuilds the project from scratch."; \
	echo "  status    Shows the status of all services."; \
	echo "  logs      Tails the logs from all running containers."; \
	echo "  clean     Removes containers and networks."; \
	echo "  fclean    Removes everything, including data and secrets."; \
	echo "  help      Shows this help message."

#
# `build`: The Docker Compose command to build or rebuild the images for all services.
#
build: setup
	@echo "--- Building Docker images... ---"
	@docker-compose -f srcs/docker-compose.yml --project-name $(PROJECT_NAME) build

#
# `up`: The Docker Compose command to start the services. It will not force a rebuild
# unless the configuration has changed.
#
up: setup
	@echo "--- Starting services... ---"
	@docker-compose -f srcs/docker-compose.yml --project-name $(PROJECT_NAME) up -d

#
# `-`: This prefix is a 'make' directive that tells it to ignore any errors from this command.
#   This is useful if you run 'down' when no containers are running, preventing an error.
# `down`: The Docker Compose command to stop and remove the project's containers and network.
#
down:
	@echo "--- Stopping services... ---"
	-@docker-compose -f srcs/docker-compose.yml --project-name $(PROJECT_NAME) down

#
# `down --remove-orphans`: This does everything `down` does, but also removes any "orphan" containers.
#   An orphan container is one that was created for a service that no longer exists in your docker-compose.yml.
#
clean:
	@echo "--- Removing containers and networks... ---"
	-@docker-compose -f srcs/docker-compose.yml --project-name $(PROJECT_NAME) down --remove-orphans

#
# `fclean` depends on `clean`. 'make' will run 'clean' first, then run the commands for 'fclean'.
#
fclean: clean
	@echo "--- Deleting all data and configuration... ---"
# `sudo rm -rf`: Forcefully (`-f`) and recursively (`-r`) deletes directories with administrator privileges.
	-@sudo rm -rf "$(HOME)/data"
	-@sudo rm -rf secrets
	-@rm -f srcs/.env
	@echo "✅ Project completely cleaned."

#
# `re` depends on `fclean` and `all`. It will run `fclean` first, then `all`.
#
re: fclean all

#
# `ps`: The Docker Compose command to list all containers in the project.
# `-a`: The '-a' (all) flag ensures it shows all containers, including those that have stopped.
#
status:
	@echo "--- Container Status ---"
	@docker-compose -f srcs/docker-compose.yml --project-name $(PROJECT_NAME) ps -a

#
# `logs`: The Docker Compose command to display logs from all services.
# `-f`: The '-f' (follow) flag streams the logs in real-time until you press Ctrl+C.
#
logs:
	@echo "--- Tailing Logs (Ctrl+C to exit) ---"
	@docker-compose -f srcs/docker-compose.yml --project-name $(PROJECT_NAME) logs -f

# --- Helper Targets ---

#
# `setup`: A target to run the initial configuration script.
# `if [ ! -f srcs/.env ]; then ... fi`: A standard shell 'if' statement.
# `[` is an alias for the 'test' command.
# `!` is the 'not' operator.
# `-f srcs/.env`: This test checks if a file exists and is a regular file.
# The commands inside the 'if' block will only execute if the .env file does *not* exist.
#
setup:
	@if [ ! -f srcs/.env ]; then \
		echo "--- Running first-time setup... ---"; \
		/bin/sh setup.sh; \
	fi

#
# `help`: A target to display a simple, hardcoded help message.
#
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

#
# `.PHONY`: A special 'make' directive. It declares that the listed targets are "phony,"
#   meaning they are names for commands to be executed, not actual files.
# Why: This prevents conflicts if a file with the same name as a target (e.g., a file named 'build')
#   exists in your directory. It also improves performance slightly.
#
.PHONY: all build up down clean fclean re status logs setup help