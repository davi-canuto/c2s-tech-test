.PHONY: help up down restart logs logs-web logs-sidekiq shell console test clean

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

up: ## Start all services (web, db, redis, sidekiq)
	docker-compose up -d

down: ## Stop all services
	docker-compose down

restart: ## Restart all services
	docker-compose restart

logs: ## Show logs from all services
	docker-compose logs -f

logs-web: ## Show web server logs
	docker-compose logs -f web

logs-sidekiq: ## Show Sidekiq logs
	docker-compose logs -f sidekiq

shell: ## Open bash shell in web container
	docker-compose exec web bash

console: ## Open Rails console
	docker-compose exec web bundle exec rails console

test: ## Run tests
	docker-compose exec web bundle exec rspec

clean: ## Remove all containers, volumes and images
	docker-compose down -v --remove-orphans

status: ## Show status of all services
	docker-compose ps

build: ## Rebuild all containers
	docker-compose build

db-migrate: ## Run database migrations
	docker-compose exec web bundle exec rails db:migrate

db-reset: ## Reset database (drop, create, migrate, seed)
	docker-compose exec web bundle exec rails db:reset

db-seed: ## Seed database
	docker-compose exec web bundle exec rails db:seed
