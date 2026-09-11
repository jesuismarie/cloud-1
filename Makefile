LIGHT_PURPLE		:= \033[1;35m
RESET				:= \033[0m

USERNAME			:= $(shell grep '^USERNAME=' srcs/.env | cut -d= -f2)
DATA_PATH			:= /home/$(USER)/data
WORDPRESS_PATH		:= $(DATA_PATH)/wordpress
MYSQL_PATH			:= $(DATA_PATH)/mysql
TF_DIR				:= ./infra/provision
all:
	@echo "${LIGHT_PURPLE}Deploying full Cloud-1 infrastructure...${RESET}"
	@$(MAKE) init plan apply
	@echo "${LIGHT_PURPLE}Infrastructure provisioned. Run 'make show' for the instance IP.${RESET}"

init:
	@echo "${LIGHT_PURPLE}Initializing Terraform...${RESET}"
	@terraform -chdir=$(TF_DIR) init

plan: init
	@echo "${LIGHT_PURPLE}Planning infrastructure changes...${RESET}"
	@terraform -chdir=$(TF_DIR) plan

apply: init
	@echo "${LIGHT_PURPLE}Applying infrastructure changes...${RESET}"
	@terraform -chdir=$(TF_DIR) apply
	@echo "${LIGHT_PURPLE}Instance is up.${RESET}"

destroy:
	@echo "${LIGHT_PURPLE}Destroying cloud infrastructure...${RESET}"
	@terraform -chdir=$(TF_DIR) destroy
	@echo "${LIGHT_PURPLE}Infrastructure destroyed.${RESET}"

remove: destroy
	@echo "${LIGHT_PURPLE}Removing local Terraform state and lock file...${RESET}"
	@rm -rf $(TF_DIR)/.terraform/ $(TF_DIR)/.terraform.lock.hcl $(TF_DIR)/.states
	@echo "${LIGHT_PURPLE}Terraform workspace cleaned.${RESET}"

redeploy: destroy all
	@echo "${LIGHT_PURPLE}Redeployment complete.${RESET}"

show:
	@echo "${LIGHT_PURPLE}Current Terraform state:${RESET}"
	@terraform -chdir=$(TF_DIR) show

format:
	@echo "${LIGHT_PURPLE}Formatting Terraform files...${RESET}"
	@terraform -chdir=$(TF_DIR) fmt

validate: init
	@echo "${LIGHT_PURPLE}Validating Terraform configuration...${RESET}"
	@terraform -chdir=$(TF_DIR) validate

graph:
	@echo "${LIGHT_PURPLE}Generating dependency graph (graph.svg)...${RESET}"
	@terraform -chdir=$(TF_DIR) graph | dot -Tsvg > graph.svg

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
		all init plan apply destroy remove redeploy show format validate graph