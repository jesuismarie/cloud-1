LIGHT_PURPLE	= \033[1;35m
RESET			= \033[0m

DATA_PATH		= /home/$(USER)/data
WORDPRESS_PATH	= $(DATA_PATH)/wordpress
MYSQL_PATH	= $(DATA_PATH)/mysql

all: create_dirs up

create_dirs:
	@mkdir -p $(WORDPRESS_PATH)
	@mkdir -p $(MYSQL_PATH)
	@echo "${LIGHT_PURPLE}Data directories created at $(DATA_PATH)${RESET}"

up:
	@echo "${LIGHT_PURPLE}Starting up containers...${RESET}"
	@docker-compose -f ./srcs/docker-compose.yml up -d --build
	@echo "${LIGHT_PURPLE}Containers are up! Access your site at https://$(USERNAME).42.fr${RESET}"

down:
	@echo "${LIGHT_PURPLE}Shutting down containers...${RESET}"
	@docker-compose -f ./srcs/docker-compose.yml down
	@echo "${LIGHT_PURPLE}Done.${RESET}"

start:
	@echo "${LIGHT_PURPLE}Starting containers...${RESET}"
	@docker-compose -f ./srcs/docker-compose.yml start
	@echo "${LIGHT_PURPLE}Done.${RESET}"

stop:
	@echo "${LIGHT_PURPLE}Stopping containers...${RESET}"
	@docker-compose -f ./srcs/docker-compose.yml stop
	@echo "${LIGHT_PURPLE}Done.${RESET}"

clean: down
	@echo "${LIGHT_PURPLE}Removing host data directories...${RESET}"
	@sudo rm -rf $(DATA_PATH)

	@echo "${LIGHT_PURPLE}Removing volumes ...${RESET}"
	@docker volume rm srcs_wordpress-volume srcs_mysql-volume 2>/dev/null || true

fclean: clean
	@echo "${LIGHT_PURPLE}Removing project Docker images...${RESET}"
	@docker rmi my-nginx my-mysql my-wordpress:php-fpm my-redis mysql:8.4 phpmyadmin/phpmyadmin:5.2 2>/dev/null || true
	@echo "${LIGHT_PURPLE}Project images removed.${RESET}"

	@echo "${LIGHT_PURPLE}Host data cleaned.${RESET}"

clean-all: fclean
	@echo "${LIGHT_PURPLE}Clearing Docker build cache...${RESET}"
	@docker builder prune -f
	@echo "${LIGHT_PURPLE}Build cache cleared.${RESET}"

	@echo "${LIGHT_PURPLE}Full clean complete!${RESET}"

re: fclean all

.PHONY: all re up down start stop create_dirs clean fclean clean-all
