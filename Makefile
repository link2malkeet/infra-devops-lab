
.PHONY: help up down build logs ps curl health ready

help:
	@echo "Targets:"
	@echo "  make up      - build and start"
	@echo "  make down    - stop"
	@echo "  make build   - build images"
	@echo "  make logs    - follow logs"
	@echo "  make ps      - show containers"
	@echo "  make curl    - call /"
	@echo "  make health  - call /healthz"
	@echo "  make ready   - call /readyz"

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
	curl -s http://localhost:8080/ | python -m json.tool

health:
	curl -s http://localhost:8080/healthz | python -m json.tool

ready:
	curl -s http://localhost:8080/readyz | python -m json.tool
