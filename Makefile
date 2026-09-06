LIGHT_PURPLE	:= \033[1;35m
RESET			:= \033[0m

USERNAME		:= $(shell grep '^USERNAME=' srcs/.env | cut -d= -f2)
DATA_PATH		:= /home/$(USER)/data
WORDPRESS_PATH	:= $(DATA_PATH)/wordpress
MYSQL_PATH		:= $(DATA_PATH)/mysql
TF_DIR			:= infra/provision
SSH_KEY_PATH	:= /home/$(USER)/.ssh/cloud1_key

all: ssh-key init plan apply

ssh-key:
	@if [ ! -f $(SSH_KEY_PATH) ]; then \
		echo "${LIGHT_PURPLE}Generating SSH key pair...${RESET}"; \
		ssh-keygen -t ed25519 -f $(SSH_KEY_PATH) -C "cloud-1-deploy" -N ""; \
	else \
		echo "${LIGHT_PURPLE}SSH key already exists, skipping.${RESET}"; \
	fi

init:
	terraform -chdir=$(TF_DIR) init

plan: ssh-key
	terraform -chdir=$(TF_DIR) plan

apply: ssh-key
	terraform -chdir=$(TF_DIR) apply

destroy:
	terraform -chdir=$(TF_DIR) destroy

redeploy: destroy ssh-key all

show:
	terraform -chdir=$(TF_DIR) show

format:
	terraform -chdir=$(TF_DIR) fmt

validate:
	terraform -chdir=$(TF_DIR) validate

graph:
	terraform -chdir=$(TF_DIR) graph | dot -Tsvg > graph.svg

local: create_dirs up

check-env:
	@if [ ! -f srcs/.env ]; then \
		echo "${LIGHT_PURPLE}Error: .env file not found in srcs directory.${RESET}"; \
		exit 1; \
	fi

create_dirs:
	@mkdir -p $(WORDPRESS_PATH)
	@mkdir -p $(MYSQL_PATH)

up: check-env
	@docker-compose -f ./srcs/docker-compose.yml up -d --build
	@echo "${LIGHT_PURPLE}Containers are up! Access your site at https://$(USERNAME).42.fr${RESET}"

down:
	@docker-compose -f ./srcs/docker-compose.yml down

clean-local: down
	@echo "${LIGHT_PURPLE}Removing project Docker images...${RESET}"
	@sudo rm -rf $(DATA_PATH)
	@docker rmi my-nginx my-mysql my-wordpress:php-fpm my-redis mysql:8.4 phpmyadmin/phpmyadmin:5.2 2>/dev/null || true
	@docker volume rm srcs_wordpress-volume srcs_mysql-volume 2>/dev/null || true
	@echo "${LIGHT_PURPLE}Host data cleaned.${RESET}"

re: clean-local local

.PHONY: local check-env re up down create_dirs clean-local \
		all ssh-key init plan apply destroy redeploy show format validate graph