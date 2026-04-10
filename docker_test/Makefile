.PHONY: help setup build up down logs clean test test-full test-full_cone test-address_restricted test-port_restricted test-symmetric results report

help:
	@echo "SHSP NAT Testing - Available commands:"
	@echo ""
	@echo "Setup:"
	@echo "  make setup              - Setup environment and build Docker images"
	@echo ""
	@echo "Testing:"
	@echo "  make test-full          - Run all NAT type tests"
	@echo "  make test-full_cone     - Test Full Cone NAT"
	@echo "  make test-address_restricted - Test Address Restricted NAT"
	@echo "  make test-port_restricted    - Test Port Restricted NAT"
	@echo "  make test-symmetric     - Test Symmetric NAT"
	@echo ""
	@echo "Docker:"
	@echo "  make build              - Build Docker images"
	@echo "  make up                 - Start containers"
	@echo "  make down               - Stop containers"
	@echo "  make logs               - Show container logs"
	@echo ""
	@echo "Results:"
	@echo "  make results            - Display JSON results"
	@echo "  make report             - Open HTML report"
	@echo "  make clean              - Clean results and containers"

setup:
	@echo "Setting up SHSP NAT Testing environment..."
	bash setup.sh

build:
	@echo "Building Docker images..."
	docker-compose build

up:
	@echo "Starting containers..."
	docker-compose up -d

down:
	@echo "Stopping containers..."
	docker-compose down

logs:
	docker-compose logs -f

test: setup test-full

test-full:
	@echo "Running all NAT type tests..."
	bash run_all_tests.sh

test-full_cone:
	@echo "Testing Full Cone NAT..."
	export NAT_TYPE=full_cone && docker-compose up --abort-on-container-exit

test-address_restricted:
	@echo "Testing Address Restricted NAT..."
	export NAT_TYPE=address_restricted && docker-compose up --abort-on-container-exit

test-port_restricted:
	@echo "Testing Port Restricted NAT..."
	export NAT_TYPE=port_restricted && docker-compose up --abort-on-container-exit

test-symmetric:
	@echo "Testing Symmetric NAT..."
	export NAT_TYPE=symmetric && docker-compose up --abort-on-container-exit

results:
	@echo "Results:"
	@if [ -f results/aggregate_results.json ]; then \
		jq . results/aggregate_results.json; \
	else \
		echo "No results found. Run 'make test' first."; \
	fi

report:
	@if [ -f results/report.html ]; then \
		open results/report.html; \
	else \
		echo "No report found. Run 'make test' first."; \
	fi

clean:
	@echo "Cleaning up..."
	docker-compose down
	rm -rf results/
	docker system prune -f

.SILENT: help
