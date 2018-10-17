DOCKER			= docker
DOCKER_COMPOSE  = docker-compose -f docker-stack.yaml

EXEC_PHP        = $(DOCKER_COMPOSE) exec -T app
EXEC_JS         = $(DOCKER_COMPOSE) exec -T node /entrypoint
EXEC_MONGODB	= $(DOCKER_COMPOSE) exec mongodb

SYMFONY         = $(EXEC_PHP) bin/console
COMPOSER        = $(EXEC_PHP) composer
YARN            = $(EXEC_JS) yarn

QA				= docker run --rm -v `pwd`:/project mykiwi/phaudit:7.2
ARTEFACTS		= app/var/artefacts

DEFAULT_DB		= postgresql
DB				?= ${DEFAULT_DB}

MYSQL			= $(shell echo $$(grep -s 'mysql' docker-stack.yaml))
POSTGRESQL		= $(shell echo $$(grep -s 'postgresql' docker-stack.yaml))
MONGODB			= $(shell echo $$(grep -s 'mongodb' docker-stack.yaml))

MONGODB_USER	= $(shell echo $$(grep MONGODB_USERNAME .env | xargs) | sed 's/.*=//')
MONGODB_NAME	= $(shell echo $$(grep MONGO_INITDB_DATABASE .env | xargs) | sed 's/.*=//')
MONGODB_PWD		= $(shell echo $$(grep MONGODB_PASSWORD .env | xargs) | sed 's/.*=//')

ifneq ($(MYSQL),)
    CURRENTLY_USED_DB = mysql
else ifneq ($(POSTGRESQL),)
	CURRENTLY_USED_DB = postgresql
else ifneq ($(MONGODB),)
	CURRENTLY_USED_DB = mongodb
endif

##
## Project
## -------
##

use-db: ## Configure the stack with the DB
	@if [ -z ${DB} ] || [ ${DB} != "mysql" -a ${DB} != "postgresql" -a ${DB} != "mongodb" ]; \
	then\
		echo '\033[1;41m/!\ Invalid value: "${DB}" \033[0m';\
		exit 1;\
	fi
	docker-compose -f docker-compose.yaml -f docker-compose.${DB}.yaml config > docker-stack.yaml
	@echo '\033[1;32m Selected DB: ${DB} \033[0m';

info:
	@if [ ! -f docker-stack.yaml ]; then\
		printf "\n";\
		echo '\033[1;41m/!\ Please run "make use-db DB=[mysql|postgresql|mongodb]" before install the project. \033[0m';\
	else\
		printf "\n";\
		echo '\033[1;32m Currently used DB: ${CURRENTLY_USED_DB} \033[0m';\
	fi

build:
	@$(DOCKER_COMPOSE) pull --parallel --quiet --ignore-pull-failures 2> /dev/null
	$(DOCKER_COMPOSE) build --pull

kill: clean-app
	$(DOCKER_COMPOSE) kill
	$(DOCKER_COMPOSE) down --volumes --remove-orphans

install: ## Install and start the project
install: .env use-db build start assets db

reset: ## Stop and start a fresh install of the project
reset: kill install

start: ## Start the project
	$(DOCKER_COMPOSE) up -d --remove-orphans

logs: ## Show all logs
	$(DOCKER_COMPOSE) logs -f

stop: ## Stop the project
	$(DOCKER_COMPOSE) stop

clean: ## Stop the project and remove generated files
clean: kill
	rm -rf .env app/.env

ps:	## List containers
	$(DOCKER) ps

.PHONY: use-db build kill install reset start stop clean ps logs

clean-app: ## Remove generated files
	$(EXEC_PHP) rm -rf vendor node_modules public/build

##
## Utils
## -----
##

db: ## Reset the database and load fixtures
db: .env vendor
	@if [ ${CURRENTLY_USED_DB} != "mongodb" ]; then\
		$(SYMFONY) doctrine:database:drop --if-exists --force;\
		$(SYMFONY) doctrine:database:create --if-not-exists;\
		$(SYMFONY) doctrine:migrations:migrate --no-interaction --allow-no-migration;\
	fi
	@echo '\033[1;32m TODO DB \033[0m';
	#$(SYMFONY) doctrine:fixtures:load --no-interaction --purge-with-truncate

migration: ## Generate a new doctrine migration
migration: vendor
	$(SYMFONY) doctrine:migrations:diff

db-validate-schema: ## Validate the doctrine ORM mapping
db-validate-schema: .env vendor
	$(SYMFONY) doctrine:schema:validate

update: ## Composer update
update:
	$(COMPOSER) update

assets: ## Run Webpack Encore to compile assets
assets: node_modules
	$(YARN) run dev

watch: ## Run Webpack Encore in watch mode
watch: node_modules
	$(YARN) run watch

production: ## Create a production build
production: node_modules
	$(YARN) run build

terminal-mongodb: ## MongoDB terminal
	$(EXEC_MONGODB) mongo $(MONGODB_NAME) -u $(MONGODB_USER) -p $(MONGODB_PWD)

.PHONY: db migration update assets watch production

##
## Tests
## -----
##

tests: ## Run unit and functional tests
tests: tu tf

tu: ## Run unit tests
tu: vendor
	$(EXEC_PHP) bin/phpunit --exclude-group functional

tf: ## Run functional tests
tf: vendor
	$(EXEC_PHP) bin/phpunit --group functional

.PHONY: tests tu tf

# rules based on files
composer.lock: app/composer.json
	$(COMPOSER) update --lock --no-scripts --no-interaction

vendor: composer.lock
	$(COMPOSER) install

node_modules: app/package.json app/yarn.lock
	$(YARN) install
	@touch -c node_modules

.env: .env.dist
	@if [ -f .env ]; \
	then\
		echo '\033[1;41m/!\ The .env.dist file has changed. Please check your .env file (this message will not be displayed again).\033[0m';\
		touch .env;\
		exit 1;\
	else\
		cp .env.dist .env;\
		cp app/.env.dist app/.env;\
	fi

##
## Quality assurance
## -----------------
##

lint: ## Lints twig and yaml files
lint: lt ly

lt: vendor
	$(SYMFONY) lint:twig templates

ly: vendor
	$(SYMFONY) lint:yaml config

security: ## Check security of your dependencies (https://security.symfony.com/)
security: vendor
	$(EXEC_PHP) ./vendor/bin/security-checker security:check

phploc: ## PHPLoc (https://github.com/sebastianbergmann/phploc)
	$(QA) phploc src/

pdepend: ## PHP_Depend (https://pdepend.org)
pdepend: artefacts
	$(QA) pdepend \
		--summary-xml=$(ARTEFACTS)/pdepend_summary.xml \
		--jdepend-chart=$(ARTEFACTS)/pdepend_jdepend.svg \
		--overview-pyramid=$(ARTEFACTS)/pdepend_pyramid.svg \
		src/

phpcpd: ## PHP Copy/Paste Detector (https://github.com/sebastianbergmann/phpcpd)
	$(QA) phpcpd src

phpdcd: ## PHP Dead Code Detector (https://github.com/sebastianbergmann/phpdcd)
	$(QA) phpdcd src

phpmetrics: ## PhpMetrics (http://www.phpmetrics.org)
phpmetrics: artefacts
	$(QA) phpmetrics --report-html=$(ARTEFACTS)/phpmetrics src

php-cs-fixer: ## php-cs-fixer (http://cs.sensiolabs.org)
	$(QA) php-cs-fixer fix --dry-run --using-cache=no --verbose --diff

apply-php-cs-fixer: ## apply php-cs-fixer fixes
	$(QA) php-cs-fixer fix --using-cache=no --verbose --diff

twigcs: ## twigcs (https://github.com/allocine/twigcs)
	$(QA) twigcs lint templates

eslint: ## eslint (https://eslint.org/)
eslint: node_modules
	$(EXEC_JS) node_modules/.bin/eslint --fix-dry-run assets/js/**

artefacts:
	mkdir -p $(ARTEFACTS)

.PHONY: lint lt ly phploc pdepend phpmd php_codesnifer phpcpd phpdcd phpmetrics php-cs-fixer apply-php-cs-fixer artefacts

.DEFAULT_GOAL := help
help: info
	@printf "\n"
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'
.PHONY: help



#mysql:	## MySQL terminal
#		$(DCS) exec mysql mysql -usymfony -psymfony
#.PHONY: mysql
#
#postgresql:	## PostgreSQL terminal
#		$(DCS) exec postgresql psql -d symfony -U symfony
#.PHONY: postgresql
#
