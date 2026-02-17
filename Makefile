
.PHONY: help up down build logs ps curl health ready metrics test

help:
	@echo "Targets:"
	@echo "  make up      - build and start all services"
	@echo "  make down    - stop all services"
	@echo "  make build   - build images"
	@echo "  make logs    - follow logs"
	@echo "  make ps      - show containers"
	@echo "  make curl    - call / (via Nginx)"
	@echo "  make health  - call /healthz"
	@echo "  make ready   - call /readyz"
	@echo "  make metrics - view Prometheus metrics"
	@echo "  make test    - run all health checks"

up:
	docker compose up --build

down:
	docker compose down

build:
	docker compose build

logs:
	docker compose logs -f

ps:
	docker compose ps

curl:
	@echo "Testing via Nginx (port 80)..."
	curl -s http://localhost/ | python -m json.tool

health:
	@echo "Testing health endpoint..."
	curl -s http://localhost/healthz | python -m json.tool

ready:
	@echo "Testing readiness endpoint..."
	curl -s http://localhost/readyz | python -m json.tool

metrics:
	@echo "Fetching Prometheus metrics..."
	curl -s http://localhost/metrics | head -20

test: health ready
	@echo "All health checks passed!"
