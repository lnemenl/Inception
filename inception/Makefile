# Inception project Makefile
.PHONY: all build up down clean fclean re logs status fix-perms fix-scripts

all: fix-perms fix-scripts
	@echo "🚀 Starting Inception project..."
	@cd srcs && docker-compose --env-file .env up --build

build:
	@echo "🔧 Building Docker images..."
	@cd srcs && docker-compose --env-file .env build

up: fix-perms fix-scripts
	@echo "🚀 Launching containers..."
	@cd srcs && docker-compose --env-file .env up -d

down:
	@echo "🛑 Stopping containers..."
	@cd srcs && docker-compose --env-file .env down

clean:
	@echo "🧹 Cleaning Docker environment..."
	@docker stop $$(docker ps -qa) 2>/dev/null || true
	@docker rm $$(docker ps -qa) 2>/dev/null || true
	@docker rmi -f $$(docker images -qa) 2>/dev/null || true
	@docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	@docker network rm $$(docker network ls -q) 2>/dev/null || true

fclean: clean
	@echo "🗑️ Removing volumes and data..."
	@sudo rm -rf /home/rkhakimu/data/mariadb/* /home/rkhakimu/data/wordpress/*
	@docker-compose -f srcs/docker-compose.yml down -v --remove-orphans

re: fclean all

logs:
	@echo "📜 Displaying container logs..."
	@cd srcs && docker-compose --env-file .env logs

status:
	@echo "📊 Checking container status..."
	@docker ps -a

fix-perms:
	@echo "🔐 Setting up volume permissions..."
	@sudo mkdir -p /home/rkhakimu/data/mariadb /home/rkhakimu/data/wordpress
	@sudo chown -R 999:999 /home/rkhakimu/data/mariadb
	@sudo chown -R 65534:65534 /home/rkhakimu/data/wordpress
	@sudo chmod -R 775 /home/rkhakimu/data/mariadb /home/rkhakimu/data/wordpress

fix-scripts:
	@echo "🔧 Setting executable permissions for scripts..."
	@chmod +x srcs/requirements/mariadb/tools/init.sh
	@chmod +x srcs/requirements/mariadb/healthcheck.sh
	@chmod +x srcs/requirements/nginx/tools/generate-certs.sh
	@chmod +x srcs/requirements/wordpress/tools/init.sh
