# Local Kubernetes Setup Guide

This guide will help you deploy your app to a local Kubernetes cluster using Minikube or Kind.

## Prerequisites

- Docker Desktop installed and running
- 2+ GB free RAM
- 20+ GB free disk space

## Option 1: Minikube (Recommended for Beginners)

### Installation

**macOS:**
```bash
brew install minikube
```

**Linux:**
```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

**Windows:**
Download from: https://minikube.sigs.k8s.io/docs/start/

### Start Minikube

```bash
# Start Minikube cluster
minikube start

# Verify cluster is running
kubectl get nodes

# Enable ingress addon (optional, for ingress support)
minikube addons enable ingress
```

### Build and Load Docker Images

Minikube uses its own Docker daemon, so we need to build images inside Minikube:

```bash
# Set Docker environment to Minikube's Docker
eval $(minikube docker-env)

# Build images
docker build -t infra-devops-lab-app:latest -f docker/Dockerfile .
docker build -t infra-devops-lab-nginx:latest -f docker/Dockerfile.nginx .

# Verify images
docker images | grep infra-devops-lab
```

### Deploy to Kubernetes

```bash
# Apply all manifests
kubectl apply -k k8s/

# Or apply individually
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/app-deployment.yaml
kubectl apply -f k8s/app-service.yaml
kubectl apply -f k8s/nginx-deployment.yaml
kubectl apply -f k8s/nginx-service.yaml
```

### Access Your App

**Option 1: NodePort (Easiest)**
```bash
# Get the NodePort URL
minikube service nginx-service -n infra-devops-lab --url

# Or access directly
curl http://localhost:30080/
```

**Option 2: Port Forward**
```bash
# Forward port to local machine
kubectl port-forward -n infra-devops-lab service/nginx-service 8080:80

# Access via
curl http://localhost:8080/
```

**Option 3: Ingress (if enabled)**
```bash
# Get ingress IP
minikube ip

# Add to /etc/hosts (or C:\Windows\System32\drivers\etc\hosts on Windows)
# <minikube-ip> infra-devops-lab.local

# Access via
curl http://infra-devops-lab.local/
```

---

## Option 2: Kind (Kubernetes in Docker)

### Installation

**macOS/Linux:**
```bash
brew install kind
# or
go install sigs.k8s.io/kind@v0.31.0
```

### Create Cluster

```bash
# Create a cluster
kind create cluster --name infra-devops-lab

# Verify
kubectl cluster-info --context kind-infra-devops-lab
```

### Build and Load Images

Kind can load images directly:

```bash
# Build images locally
docker build -t infra-devops-lab-app:latest -f docker/Dockerfile .
docker build -t infra-devops-lab-nginx:latest -f docker/Dockerfile.nginx .

# Load into Kind cluster
kind load docker-image infra-devops-lab-app:latest --name infra-devops-lab
kind load docker-image infra-devops-lab-nginx:latest --name infra-devops-lab
```

### Deploy to Kubernetes

```bash
# Apply all manifests
kubectl apply -k k8s/
```

### Access Your App

**Port Forward:**
```bash
kubectl port-forward -n infra-devops-lab service/nginx-service 8080:80
curl http://localhost:8080/
```

**NodePort:**
```bash
# Access via NodePort (30080)
kubectl get svc -n infra-devops-lab nginx-service
curl http://localhost:30080/
```

---

## Useful Commands

### Check Status

```bash
# Check pods
kubectl get pods -n infra-devops-lab

# Check services
kubectl get svc -n infra-devops-lab

# Check deployments
kubectl get deployments -n infra-devops-lab

# Describe a pod (for debugging)
kubectl describe pod <pod-name> -n infra-devops-lab
```

### View Logs

```bash
# App logs
kubectl logs -n infra-devops-lab -l component=app --tail=50

# Nginx logs
kubectl logs -n infra-devops-lab -l component=nginx --tail=50

# Follow logs
kubectl logs -n infra-devops-lab -l component=app -f
```

### Scale Deployment

```bash
# Scale app to 3 replicas
kubectl scale deployment app -n infra-devops-lab --replicas=3

# Check scaling
kubectl get pods -n infra-devops-lab
```

### Update Configuration

```bash
# Edit configmap
kubectl edit configmap app-config -n infra-devops-lab

# Restart pods to pick up changes
kubectl rollout restart deployment app -n infra-devops-lab
```

### Delete Everything

```bash
# Delete all resources
kubectl delete -k k8s/

# Or delete namespace (deletes everything in namespace)
kubectl delete namespace infra-devops-lab
```

---

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n infra-devops-lab

# Describe pod for errors
kubectl describe pod <pod-name> -n infra-devops-lab

# Check events
kubectl get events -n infra-devops-lab --sort-by='.lastTimestamp'
```

### Image Pull Errors

If you see `ImagePullBackOff`:
- Make sure images are built and loaded into cluster
- For Minikube: Use `eval $(minikube docker-env)` before building
- For Kind: Use `kind load docker-image` after building

### Can't Access Service

```bash
# Check service endpoints
kubectl get endpoints -n infra-devops-lab

# Test from inside cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl http://app-service:8080/
```

### Health Check Failures

```bash
# Check health check status
kubectl describe pod <pod-name> -n infra-devops-lab | grep -A 5 "Liveness\|Readiness"

# Test health endpoint manually
kubectl exec -n infra-devops-lab <pod-name> -- curl http://localhost:8080/healthz
```

---

## Minikube Dashboard (Optional)

```bash
# Start dashboard
minikube dashboard

# Or access via port-forward
kubectl port-forward -n kube-system service/kubernetes-dashboard 8080:443
```

---

## Cleanup

### Minikube
```bash
# Stop cluster
minikube stop

# Delete cluster
minikube delete
```

### Kind
```bash
# Delete cluster
kind delete cluster --name infra-devops-lab
```

---

## Next Steps

1. **Learn Kubernetes Concepts**: Deployments, Services, ConfigMaps
2. **Add Ingress**: For better routing and SSL
3. **Add Monitoring**: Prometheus + Grafana
4. **Add Secrets**: For sensitive configuration
5. **Deploy to Cloud**: Use same manifests for cloud K8s

---

## Quick Reference

```bash
# Start Minikube
minikube start

# Build images (Minikube)
eval $(minikube docker-env)
docker build -t infra-devops-lab-app:latest -f docker/Dockerfile .
docker build -t infra-devops-lab-nginx:latest -f docker/Dockerfile.nginx .

# Deploy
kubectl apply -k k8s/

# Access
minikube service nginx-service -n infra-devops-lab --url

# Cleanup
kubectl delete -k k8s/
minikube stop
```

Happy Kubernetes learning! 🚀
