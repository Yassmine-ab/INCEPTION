################################################################################
#                                     COLORS                                   #
################################################################################

DEFAULT			= \033[0m
RED				= \033[1;31m
GREEN			= \033[1;32m
YELLOW			= \033[1;33m
BLUE			= \033[1;34m
MAGENTA			= \033[1;35m
CYAN			= \033[1;36m
LIGHT_CYAN		= \033[1;96m
WHITE			= \033[1;37m

################################################################################
#                                     HEADER                                   #
################################################################################

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

################################################################################
#                                     CONFIG                                   #
################################################################################

COMPOSE_FILE	= ./srcs/docker-compose.yml
DATA_PATH		= /home/yaabdall/data
LOGIN			= yaabdall

################################################################################
#                                     RULES                                    #
################################################################################

all:
				@echo "$$HEADER"
				@echo "\n🚀 $(GREEN)Starting Inception...$(DEFAULT)\n"
				@mkdir -p $(DATA_PATH)/wordpress
				@mkdir -p $(DATA_PATH)/mariadb
				@docker-compose -f $(COMPOSE_FILE) up -d --build
				@echo "\n✅ $(GREEN)Inception is running!$(DEFAULT)"
				@echo "🌐 Visit: $(CYAN)https://$(LOGIN).42.fr$(DEFAULT)\n"

up:
				@docker-compose -f $(COMPOSE_FILE) up -d
				@echo "\n✅ $(GREEN)Services started$(DEFAULT)\n"

down:
				@docker-compose -f $(COMPOSE_FILE) down
				@echo "\n� $(YELLOW)Services stopped$(DEFAULT)\n"

stop:
				@docker-compose -f $(COMPOSE_FILE) stop
				@echo "\n⏸️  $(YELLOW)Services paused$(DEFAULT)\n"

start:
				@docker-compose -f $(COMPOSE_FILE) start
				@echo "\n▶️  $(GREEN)Services resumed$(DEFAULT)\n"

status:
				@docker-compose -f $(COMPOSE_FILE) ps

logs:
				@docker-compose -f $(COMPOSE_FILE) logs -f

clean:			down
				@echo "🧹 $(RED)Cleaning containers and networks...$(DEFAULT)"
				@docker system prune -af
				@echo "✅ $(GREEN)Clean completed$(DEFAULT)\n"

fclean:			down
				@echo "🗑️  $(RED)Removing all containers, networks, images and volumes...$(DEFAULT)"
				@docker system prune -af --volumes
				@sudo rm -rf $(DATA_PATH)/wordpress
				@sudo rm -rf $(DATA_PATH)/mariadb
				@echo "✅ $(GREEN)Full clean completed$(DEFAULT)\n"

re:				fclean all

help:
				@echo "\n$(CYAN)all$(DEFAULT)		- Build and start all services"
				@echo "$(CYAN)up$(DEFAULT)		- Start all services"
				@echo "$(CYAN)down$(DEFAULT)		- Stop all services"
				@echo "$(CYAN)stop$(DEFAULT)		- Pause all services"
				@echo "$(CYAN)start$(DEFAULT)		- Resume all services"
				@echo "$(CYAN)status$(DEFAULT)		- Show services status"
				@echo "$(CYAN)logs$(DEFAULT)		- Show and follow services logs"
				@echo "$(CYAN)clean$(DEFAULT)		- Stop and remove containers/networks"
				@echo "$(CYAN)fclean$(DEFAULT)		- Full cleanup (containers/networks/volumes/data)"
				@echo "$(CYAN)re$(DEFAULT)		- Rebuild everything from scratch\n"

.PHONY:			all up down stop start status logs clean fclean re help
