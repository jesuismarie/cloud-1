LIGHT_PURPLE	:= \033[1;35m
RESET			:= \033[0m

DATA_PATH		:= /home/$(USER)/data
WORDPRESS_PATH	:= $(DATA_PATH)/wordpress
MYSQL_PATH		:= $(DATA_PATH)/mysql
TF_DIR			:= infra/provision

init:
	terraform -chdir=$(TF_DIR) init

plan:
	terraform -chdir=$(TF_DIR) plan

apply:
	terraform -chdir=$(TF_DIR) apply

destroy:
	terraform -chdir=$(TF_DIR) destroy

show:
	terraform -chdir=$(TF_DIR) show

format:
	terraform -chdir=$(TF_DIR) fmt

validate:
	terraform -chdir=$(TF_DIR) validate

graph:
	terraform -chdir=$(TF_DIR) graph | dot -Tsvg > graph.svg

local: create_dirs up

create_dirs:
	@mkdir -p $(WORDPRESS_PATH)
	@mkdir -p $(MYSQL_PATH)

up:
	@docker-compose -f ./srcs/docker-compose.yml up -d --build
	@echo "${LIGHT_PURPLE}Containers are up! Access your site at https://$(USERNAME).42.fr${RESET}"

down:
	@docker-compose -f ./srcs/docker-compose.yml down
	@echo "${LIGHT_PURPLE}Done.${RESET}"

clean-local:
	@echo "${LIGHT_PURPLE}Removing project Docker images...${RESET}"
	@sudo rm -rf $(DATA_PATH)
	@docker rmi my-nginx my-mysql my-wordpress:php-fpm my-redis mysql:8.4 phpmyadmin/phpmyadmin:5.2 2>/dev/null || true
	@docker volume rm srcs_wordpress-volume srcs_mysql-volume 2>/dev/null || true
	@echo "${LIGHT_PURPLE}Host data cleaned.${RESET}"

re: fclean local

.PHONY: local re up down create_dirs clean-local \
		init plan apply destroy show format validate graph