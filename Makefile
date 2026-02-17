
.PHONY: help up down build logs ps curl health ready metrics test k8s-deploy k8s-delete k8s-logs k8s-status k8s-minikube-setup

help:
	@echo "Docker Compose Targets:"
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
	@echo ""
	@echo "Kubernetes Targets:"
	@echo "  make k8s-minikube-setup - setup Minikube and build images"
	@echo "  make k8s-deploy         - deploy to Kubernetes"
	@echo "  make k8s-delete         - delete from Kubernetes"
	@echo "  make k8s-status        - show Kubernetes status"
	@echo "  make k8s-logs          - show Kubernetes logs"

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

# Kubernetes targets
k8s-minikube-setup:
	@echo "Setting up Minikube..."
	@minikube start || echo "Minikube already running"
	@echo "Configuring Docker environment..."
	@eval $$(minikube docker-env) && \
		docker build -t infra-devops-lab-app:latest -f docker/Dockerfile . && \
		docker build -t infra-devops-lab-nginx:latest -f docker/Dockerfile.nginx .
	@echo "Images built and loaded into Minikube!"

k8s-deploy:
	@echo "Deploying to Kubernetes..."
	kubectl apply -k k8s/
	@echo "Waiting for pods to be ready..."
	kubectl wait --for=condition=ready pod -l app=infra-devops-lab -n infra-devops-lab --timeout=120s
	@echo "Deployment complete!"
	@echo "Access via: minikube service nginx-service -n infra-devops-lab --url"

k8s-delete:
	@echo "Deleting from Kubernetes..."
	kubectl delete -k k8s/ || true
	@echo "Cleanup complete!"

k8s-status:
	@echo "=== Namespaces ==="
	kubectl get namespaces | grep infra-devops-lab || echo "Namespace not found"
	@echo ""
	@echo "=== Pods ==="
	kubectl get pods -n infra-devops-lab
	@echo ""
	@echo "=== Services ==="
	kubectl get svc -n infra-devops-lab
	@echo ""
	@echo "=== Deployments ==="
	kubectl get deployments -n infra-devops-lab

k8s-logs:
	@echo "=== App Logs ==="
	kubectl logs -n infra-devops-lab -l component=app --tail=50
	@echo ""
	@echo "=== Nginx Logs ==="
	kubectl logs -n infra-devops-lab -l component=nginx --tail=50

k8s-test:
	@echo "Testing Kubernetes deployment..."
	@echo ""
	@echo "=== Home Endpoint ==="
	@curl -s http://localhost:30080/ | python3 -m json.tool || echo "❌ Failed - try: minikube service nginx-service -n infra-devops-lab --url"
	@echo ""
	@echo "=== Health Check ==="
	@curl -s http://localhost:30080/healthz | python3 -m json.tool || echo "❌ Failed"
	@echo ""
	@echo "=== Readiness Check ==="
	@curl -s http://localhost:30080/readyz | python3 -m json.tool || echo "❌ Failed"
	@echo ""
	@echo "✅ Tests complete!"

k8s-url:
	@echo "Getting service URL..."
	@minikube service nginx-service -n infra-devops-lab --url || echo "Run: kubectl port-forward -n infra-devops-lab service/nginx-service 8080:80"

k8s-port-forward:
	@echo "Starting port forward (Ctrl+C to stop)..."
	@kubectl port-forward -n infra-devops-lab service/nginx-service 8080:80
