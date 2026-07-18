# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ LAYOUT ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DEFAULT			= \033[0m
GREEN			= \033[1;32m
CYAN			= \033[1;36m

define ANIMATION_FRAME
				@for frame in ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏; do \
				printf "\033[2K$$frame $(1)...\r"; \
				sleep 0.02; \
				done; \
				printf "\n"
endef

define HEADER

	$(CYAN)╔═══════ $(WHITE)by yaabdall$(CYAN) ═════════════════════════════════════════════════════╗$(DEFAULT)
	$(CYAN)║                                                                         ║$(DEFAULT)
	$(CYAN)║                                                                         ║$(DEFAULT)
	$(CYAN)║      ▄▄▄▄▄                                ▄      ▀                      ║$(DEFAULT)
	$(LIGHT_CYAN)║        █    ▄ ▄▄    ▄▄▄    ▄▄▄   ▄▄▄▄   ▄▄█▄▄  ▄▄▄     ▄▄▄   ▄ ▄▄       ║$(DEFAULT)
	$(LIGHT_CYAN)║        █    █▀  █  █▀  ▀  █▀  █  █▀ ▀█    █      █    █▀ ▀█  █▀  █      ║$(DEFAULT)
	$(LIGHT_CYAN)║        █    █   █  █      █▀▀▀▀  █   █    █      █    █   █  █   █      ║$(DEFAULT)
	$(LIGHT_CYAN)║      ▄▄█▄▄  █   █  ▀█▄▄▀  ▀█▄▄▀  ██▄█▀    ▀▄▄  ▄▄█▄▄  ▀█▄█▀  █   █      ║$(DEFAULT)
	$(LIGHT_CYAN)║                                  █                                      ║$(DEFAULT)
	$(WHITE)║                                                                         ║$(DEFAULT)
	$(WHITE)║                                                                         ║$(DEFAULT)
	$(WHITE)╚═════════════════════════════════════════════════════════════════════════╝$(DEFAULT)

endef
export HEADER


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ VARIABLES ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

FILE_COUNT =	$(words $(SRC))
COMPOSE_FILE	= ./srcs/docker-compose.yml
DATA_PATH		= /home/yaabdall/data
LOGIN			= yassabda


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ RULES ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

all:
				@echo "$$HEADER"
				@echo "\n🚀 $(GREEN)Starting Inception...$(DEFAULT)\n"
				@mkdir -p $(DATA_PATH)/wordpress
				@mkdir -p $(DATA_PATH)/mariadb
				@docker compose -f $(COMPOSE_FILE) up -d --build
				@echo "\n✅ $(GREEN)Inception is running!$(DEFAULT)"
				@echo "🌐 Visit: $(CYAN)https://$(LOGIN).42.fr$(DEFAULT)\n"

clean:			down
				$(call ANIMATION_FRAME,Cleaning containers and networks...)
				@docker system prune -af
				@printf "$(GREEN)✓$(DEFAULT) Cleaned\n"

fclean:			down
				$(call ANIMATION_FRAME,Removing all containers, networks, images and volumes...)
				@docker system prune -af --volumes
				@sudo rm -rf $(DATA_PATH)
				@printf "$(GREEN)✓$(DEFAULT) Removed\n"

re:				fclean all

up:
				@docker compose -f $(COMPOSE_FILE) up -d
				@echo "\n✅ $(GREEN)Services started$(DEFAULT)\n"

down:
				@docker compose -f $(COMPOSE_FILE) down
				@echo "\n❌ $(YELLOW)Services stopped$(DEFAULT)\n"

stop:
				@docker compose -f $(COMPOSE_FILE) stop
				@echo "\n⏸️ $(YELLOW)Services paused$(DEFAULT)\n"

start:
				@docker compose -f $(COMPOSE_FILE) start
				@echo "\n▶️ $(GREEN)Services resumed$(DEFAULT)\n"

status:
				@docker compose -f $(COMPOSE_FILE) ps

logs:
				@docker compose -f $(COMPOSE_FILE) logs -f

help:
				@printf "Usage: make [target]\n"
				@printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
				@printf "$(CYAN)all$(DEFAULT)		- Build and start all services\n"
				@printf "$(CYAN)clean$(DEFAULT)		- Stop and remove containers/networks\n"
				@printf "$(CYAN)fclean$(DEFAULT)		- Full cleanup (containers/networks/volumes/data)\n"
				@printf "$(CYAN)re$(DEFAULT)		- Rebuild everything from scratch\n"
				@printf "$(CYAN)up$(DEFAULT)		- Start all services\n"
				@printf "$(CYAN)down$(DEFAULT)		- Stop all services\n"
				@printf "$(CYAN)stop$(DEFAULT)		- Pause all services\n"
				@printf "$(CYAN)start$(DEFAULT)		- Resume all services\n"
				@printf "$(CYAN)status$(DEFAULT)		- Show services status\n"
				@printf "$(CYAN)logs$(DEFAULT)		- Show and follow services logs\n"				
				@printf "$(CYAN)help$(DEFAULT)		- Show this help message\n"

.PHONY:			all clean fclean re up down stop start status logs help
