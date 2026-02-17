# Architecture v2 - Production Ready

## Overview
Production-ready version with reverse proxy, monitoring, and cloud deployment support.

## Components

### Application Layer
- **Flask Application**: Python web service
- **Gunicorn**: Production WSGI server
- **Port**: 8080 (internal)

### Reverse Proxy Layer
- **Nginx**: Reverse proxy and load balancer
- **Port**: 80 (external)
- **Features**:
  - Rate limiting
  - Gzip compression
  - Health check routing
  - Security headers

### Observability
- **Prometheus Metrics**: `/metrics` endpoint
- **Structured Logging**: JSON format with request IDs
- **Health Checks**: `/healthz` (liveness), `/readyz` (readiness)

### Security
- Non-root container execution
- Security headers (X-Frame-Options, etc.)
- Rate limiting
- Request ID tracking

## Architecture Diagram

```
Internet
   │
   ▼
[Load Balancer / ALB] (Cloud)
   │
   ▼
[Nginx Reverse Proxy] (Port 80)
   │
   ├─ Rate Limiting
   ├─ Compression
   └─ Health Checks
   │
   ▼
[Flask App + Gunicorn] (Port 8080)
   │
   ├─ Multiple Workers
   ├─ Prometheus Metrics
   └─ Structured Logging
```

## Deployment Options

### Option 1: Container Orchestration (Recommended)
- **Kubernetes**: Full control, complex
- **ECS/Fargate**: AWS managed, simpler
- **Cloud Run**: Serverless, auto-scaling

### Option 2: VM Deployment
- **EC2**: Full control, manual management
- **Compute Engine**: GCP equivalent
- **Azure VM**: Azure equivalent

### Option 3: Serverless
- **Cloud Run**: Google Cloud
- **App Runner**: AWS
- **Container Apps**: Azure

## Networking

### Local Development
- Docker Compose network: `app-network`
- App accessible via Nginx on port 80
- Direct app access on port 8080 (for debugging)

### Production
- Load balancer → Nginx → App
- Health checks at load balancer level
- Service discovery via DNS/Service mesh

## Scaling Strategy

### Horizontal Scaling
- Multiple container instances
- Load balancer distributes traffic
- Stateless application design

### Vertical Scaling
- Adjust Gunicorn workers
- Increase container resources
- Optimize application code

## Monitoring & Alerting

### Metrics
- HTTP request rate
- Request latency (p50, p95, p99)
- Error rate
- Worker health

### Logs
- Structured JSON logs
- Request tracing via request IDs
- Centralized log aggregation (CloudWatch, Stackdriver, etc.)

### Alerts
- High error rate (> 5%)
- High latency (p95 > 1s)
- Health check failures
- Container crashes

## Assumptions

- Stateless application (no session storage)
- External database (if needed)
- Cloud provider managed services
- Container orchestration platform

## Future Enhancements

- [ ] Database integration (PostgreSQL)
- [ ] Caching layer (Redis)
- [ ] Message queue (RabbitMQ/SQS)
- [ ] Service mesh (Istio/Linkerd)
- [ ] Distributed tracing (Jaeger/Zipkin)
- [ ] CI/CD pipeline (GitHub Actions/GitLab CI)
