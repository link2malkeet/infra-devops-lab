# Deployment Guide

## Production-Ready Features

This application includes the following production-ready features:

### Security
- ✅ Security headers (X-Frame-Options, X-Content-Type-Options, etc.)
- ✅ Non-root user execution
- ✅ Rate limiting via Nginx
- ✅ Request ID tracking for security auditing

### Observability
- ✅ Structured JSON logging
- ✅ Prometheus metrics endpoint (`/metrics`)
- ✅ Request ID tracking for distributed tracing
- ✅ Health checks (`/healthz`, `/readyz`)

### Reliability
- ✅ Graceful shutdown handling
- ✅ Error handling and recovery
- ✅ Health checks with retries
- ✅ Nginx reverse proxy with load balancing

### Performance
- ✅ Multi-stage Docker builds (smaller images)
- ✅ Gunicorn with configurable workers
- ✅ Nginx with gzip compression
- ✅ Connection pooling

## Local Development

### Prerequisites
- Docker & Docker Compose
- Make (optional, for convenience commands)

### Quick Start

```bash
# Copy environment file
cp .env.example .env

# Build and start services
make up

# Or manually:
docker compose up --build
```

### Test the Application

```bash
# Test home endpoint
make curl

# Test health check
make health

# Test readiness
make ready

# View metrics
curl http://localhost/metrics
```

## Cloud Deployment

### AWS ECS / Fargate

1. **Build and push Docker image:**
```bash
# Build image
docker build -t infra-devops-lab:latest -f docker/Dockerfile .

# Tag for ECR
docker tag infra-devops-lab:latest <account>.dkr.ecr.<region>.amazonaws.com/infra-devops-lab:latest

# Push to ECR
docker push <account>.dkr.ecr.<region>.amazonaws.com/infra-devops-lab:latest
```

2. **Create ECS Task Definition:**
   - Use the Docker image
   - Set environment variables from `.env.example`
   - Configure health checks pointing to `/healthz`
   - Set memory/CPU limits

3. **Create ECS Service:**
   - Use Application Load Balancer
   - Configure target group health checks
   - Set desired count (start with 2-3 instances)

4. **Configure ALB:**
   - Health check path: `/healthz`
   - Health check interval: 30s
   - Unhealthy threshold: 2

### Google Cloud Run

1. **Build and deploy:**
```bash
# Build image
gcloud builds submit --tag gcr.io/<project-id>/infra-devops-lab

# Deploy to Cloud Run
gcloud run deploy infra-devops-lab \
  --image gcr.io/<project-id>/infra-devops-lab \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars APP_PORT=8080,LOG_LEVEL=info \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 1 \
  --max-instances 10
```

### Azure Container Instances

```bash
# Build and push to ACR
az acr build --registry <registry-name> --image infra-devops-lab:latest .

# Deploy container instance
az container create \
  --resource-group <resource-group> \
  --name infra-devops-lab \
  --image <registry-name>.azurecr.io/infra-devops-lab:latest \
  --cpu 1 \
  --memory 1 \
  --ports 8080 \
  --environment-variables APP_PORT=8080 LOG_LEVEL=info
```

### Kubernetes

1. **Create deployment:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: infra-devops-lab
spec:
  replicas: 3
  selector:
    matchLabels:
      app: infra-devops-lab
  template:
    metadata:
      labels:
        app: infra-devops-lab
    spec:
      containers:
      - name: app
        image: infra-devops-lab:latest
        ports:
        - containerPort: 8080
        env:
        - name: APP_PORT
          value: "8080"
        - name: LOG_LEVEL
          value: "info"
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /readyz
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
```

2. **Create service:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: infra-devops-lab
spec:
  selector:
    app: infra-devops-lab
  ports:
  - port: 80
    targetPort: 8080
  type: LoadBalancer
```

## Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `APP_PORT` | Application port | `8080` | Yes |
| `APP_VERSION` | Application version | `dev` | No |
| `WEB_CONCURRENCY` | Gunicorn workers | `2` | No |
| `GUNICORN_THREADS` | Threads per worker | `2` | No |
| `LOG_LEVEL` | Logging level | `info` | No |
| `NGINX_PORT` | Nginx port | `80` | No |

## Monitoring

### Prometheus Metrics

The application exposes Prometheus metrics at `/metrics`:

- `http_requests_total` - Total HTTP requests by method, endpoint, status
- `http_request_duration_seconds` - Request duration histogram

### Health Checks

- **Liveness**: `GET /healthz` - Checks if process is alive
- **Readiness**: `GET /readyz` - Checks if service is ready for traffic

### Logging

All logs are structured JSON format:
```json
{
  "ts": "2026-02-17T11:39:08.072357+00:00",
  "level": "info",
  "event": "http_request",
  "service": "infra-devops-lab",
  "method": "GET",
  "path": "/healthz",
  "status_code": 200,
  "request_id": "uuid-here"
}
```

## Scaling Recommendations

### Small (< 100 req/s)
- Workers: 2
- Threads: 2
- Instances: 1-2

### Medium (100-1000 req/s)
- Workers: 4
- Threads: 4
- Instances: 2-5

### Large (> 1000 req/s)
- Workers: 8+
- Threads: 4-8
- Instances: 5+

## Security Checklist

- [x] Non-root user in containers
- [x] Security headers configured
- [x] Rate limiting enabled
- [x] Health checks configured
- [x] Secrets in environment variables (not hardcoded)
- [ ] SSL/TLS certificates (configure at load balancer)
- [ ] WAF (Web Application Firewall) at edge
- [ ] Regular security updates

## Troubleshooting

### Check logs
```bash
docker compose logs -f app
```

### Check metrics
```bash
curl http://localhost/metrics
```

### Test health
```bash
curl http://localhost/healthz
curl http://localhost/readyz
```

### Debug container
```bash
docker compose exec app sh
```
