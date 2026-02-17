# Kubernetes Manifests

This directory contains Kubernetes manifests for deploying the infra-devops-lab application.

## Files

- `namespace.yaml` - Creates the namespace
- `configmap.yaml` - Application configuration
- `app-deployment.yaml` - Flask app deployment
- `app-service.yaml` - Flask app service (ClusterIP)
- `nginx-deployment.yaml` - Nginx reverse proxy deployment
- `nginx-service.yaml` - Nginx service (NodePort)
- `ingress.yaml` - Ingress resource (optional)
- `kustomization.yaml` - Kustomize configuration

## Quick Start

### Using Minikube

```bash
# 1. Setup Minikube and build images
make k8s-minikube-setup

# 2. Deploy to Kubernetes
make k8s-deploy

# 3. Access the app
minikube service nginx-service -n infra-devops-lab --url

# 4. Check status
make k8s-status

# 5. View logs
make k8s-logs

# 6. Cleanup
make k8s-delete
```

### Manual Deployment

```bash
# Apply all resources
kubectl apply -k k8s/

# Or apply individually
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/app-deployment.yaml
kubectl apply -f k8s/app-service.yaml
kubectl apply -f k8s/nginx-deployment.yaml
kubectl apply -f k8s/nginx-service.yaml
```

## Architecture

```
┌─────────────────┐
│  Nginx Service  │ (NodePort: 30080)
│   (Port 80)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  App Service    │ (ClusterIP)
│   (Port 8080)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  App Pods       │ (2 replicas)
│  (Flask +       │
│   Gunicorn)     │
└─────────────────┘
```

## Configuration

Edit `configmap.yaml` to change environment variables:

```yaml
data:
  APP_PORT: "8080"
  WEB_CONCURRENCY: "2"
  LOG_LEVEL: "info"
```

After editing, restart pods:
```bash
kubectl rollout restart deployment app -n infra-devops-lab
```

## Scaling

```bash
# Scale app to 3 replicas
kubectl scale deployment app -n infra-devops-lab --replicas=3

# Scale nginx to 2 replicas
kubectl scale deployment nginx -n infra-devops-lab --replicas=2
```

## Access Methods

1. **NodePort**: `http://localhost:30080` (or minikube IP:30080)
2. **Port Forward**: `kubectl port-forward -n infra-devops-lab svc/nginx-service 8080:80`
3. **Ingress**: If ingress controller is installed, use `ingress.yaml`

## Troubleshooting

See `docs/local-kubernetes-setup.md` for detailed troubleshooting guide.
