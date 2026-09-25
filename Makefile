LIGHT_PURPLE		:= \033[1;35m
RESET				:= \033[0m

USERNAME			:= $(shell grep '^USERNAME=' srcs/.env | cut -d= -f2)
DATA_PATH			:= /opt/data
WORDPRESS_PATH		:= $(DATA_PATH)/wordpress
MYSQL_PATH			:= $(DATA_PATH)/mysql
TF_DIR				:= ./infra/provision
ANSIBLE_DIR			:= ./infra/configuration
ANSIBLE_CONFIG		:= $(ANSIBLE_DIR)/ansible.cfg
SSH_KEY_PATH		:= /home/$(USER)/.ssh/cloud1_key
DEFAULT_KEY_NAME	:= cloud1_key

all:
	@echo "${LIGHT_PURPLE}Deploying full Cloud-1 infrastructure...${RESET}"
	@$(MAKE) ssh-key init apply deploy
	@echo "${LIGHT_PURPLE}Infrastructure provisioned. Run 'make show' for the instance IP.${RESET}"

ssh-key:
	@key_path=$$(eval echo $(SSH_KEY_PATH)); \
	if [ ! -f $$key_path ]; then \
		if [ -t 0 ]; then \
			read -p "SSH key not found. Path to save it [$$key_path]: " input_path; \
			input_path=$${input_path:-$$key_path}; \
			key_path=$$(eval echo $$input_path); \
		fi; \
		case "$$key_path" in \
			*/) key_path="$${key_path}$(DEFAULT_KEY_NAME)" ;; \
		esac; \
		if [ -d "$$key_path" ]; then \
			key_path="$${key_path%/}/$(DEFAULT_KEY_NAME)"; \
		fi; \
		mkdir -p $$(dirname $$key_path); \
		echo "${LIGHT_PURPLE}Generating SSH key pair at $$key_path...${RESET}"; \
		ssh-keygen -t ed25519 -f $$key_path -C "cloud-1-deploy" -N ""; \
	else \
		echo "${LIGHT_PURPLE}SSH key already exists, skipping.${RESET}"; \
	fi

init:
	@echo "${LIGHT_PURPLE}Initializing Terraform...${RESET}"
	@terraform -chdir=$(TF_DIR) init

plan: init ssh-key
	@echo "${LIGHT_PURPLE}Planning infrastructure changes...${RESET}"
	@terraform -chdir=$(TF_DIR) plan

apply: init ssh-key
	@echo "${LIGHT_PURPLE}Applying infrastructure changes...${RESET}"
	@terraform -chdir=$(TF_DIR) apply
	@echo "${LIGHT_PURPLE}Instance is up.${RESET}"

deploy:
	@echo "${LIGHT_PURPLE}Running Ansible playbook...${RESET}"
	@cd $(ANSIBLE_DIR) && ansible-playbook playbooks/main.yml
	@echo "${LIGHT_PURPLE}Ansible playbook executed.${RESET}"

destroy:
	@echo "${LIGHT_PURPLE}Destroying cloud infrastructure...${RESET}"
	@terraform -chdir=$(TF_DIR) destroy
	@echo "${LIGHT_PURPLE}Infrastructure destroyed.${RESET}"

remove: destroy
	@echo "${LIGHT_PURPLE}Removing local Terraform state and lock file...${RESET}"
	@rm -rf $(TF_DIR)/.terraform/ $(TF_DIR)/.terraform.lock.hcl $(TF_DIR)/.states
	@echo "${LIGHT_PURPLE}Terraform workspace cleaned.${RESET}"

redeploy: remove ssh-key all
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
		all ssh-key init plan apply deploy destroy remove redeploy show format validate graph