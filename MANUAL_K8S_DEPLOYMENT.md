# 🐳 Gmail File Upload - Manual Kubernetes Deployment

This guide shows you how to deploy your Gmail file upload application to Kubernetes manually without DevSpace. Perfect for production deployments or when you want full control over the process.

## 📋 **What You'll Learn**

- How to build Docker images manually
- How to deploy to Kubernetes using kubectl
- How to manage your application lifecycle
- How to access your application from localhost
- How to update your application with new changes

## 🛠️ **Prerequisites**

### Required Tools
```bash
# Make sure you have these installed:
# 1. Docker Desktop (for building images)
# 2. Minikube (for local Kubernetes cluster)
# 3. kubectl (for Kubernetes management)

# Check if everything is installed:
docker --version
minikube version
kubectl version --client
```

## 🚀 **Manual Deployment Steps**

### Step 1: Start Minikube
```bash
# Start Minikube with Docker driver
minikube start --driver=docker

# Verify Minikube is running
minikube status

# Configure Docker to use Minikube's Docker daemon
# Windows PowerShell:
& minikube -p minikube docker-env --shell powershell | Invoke-Expression

# Alternative for Command Prompt:
# @FOR /f "tokens=*" %i IN ('minikube -p minikube docker-env --shell cmd') DO @%i
```

### Step 2: Build Docker Images
```bash
# Navigate to your project directory
cd "C:\Users\AnshikaSaxena\Downloads\gmail file upload\gmail file upload"

# Build backend image
docker build -f Dockerfile.backend -t gmail-backend:latest .

# Build frontend image  
docker build -f Dockerfile.frontend -t gmail-frontend:latest .

# Verify images are built
docker images | grep gmail
```

### Step 3: Deploy to Kubernetes
```bash
# Apply all Kubernetes manifests in order
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/persistent-volume.yaml
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/frontend-deployment.yaml

# Check if everything is running
kubectl get all -n gmail-upload
```

### Step 4: Wait for Pods to be Ready
```bash
# Watch pods until they're running
kubectl get pods -n gmail-upload -w

# You should see something like:
# NAME                                   READY   STATUS    RESTARTS   AGE
# backend-deployment-xxx                 1/1     Running   0          2m
# frontend-deployment-xxx                1/1     Running   0          2m

# Press Ctrl+C to stop watching
```

### Step 5: Access Your Application

#### Option A: Port Forwarding (Recommended for Development)
```bash
# Forward frontend port (run in separate terminal windows)
kubectl port-forward service/frontend-service 5001:5001 -n gmail-upload

# Forward backend port (for API access)
kubectl port-forward service/backend-service 8000:8000 -n gmail-upload

# Now access:
# Frontend: http://localhost:5001
# Backend API: http://localhost:8000/docs
```

#### Option B: NodePort Access (Alternative)
```bash
# Get Minikube IP
minikube ip

# Get NodePort for frontend
kubectl get service frontend-service -n gmail-upload

# Access frontend at: http://<minikube-ip>:30001
# Example: http://192.168.49.2:30001
```

## 🔄 **Making Changes to Your Code**

Unlike DevSpace, manual deployment requires rebuilding and redeploying when you make changes:

### For Backend Changes:
```bash
# 1. Make your code changes
# 2. Rebuild the backend image
docker build -f Dockerfile.backend -t gmail-backend:latest .

# 3. Restart the backend deployment
kubectl rollout restart deployment/backend-deployment -n gmail-upload

# 4. Wait for rollout to complete
kubectl rollout status deployment/backend-deployment -n gmail-upload
```

### For Frontend Changes:
```bash
# 1. Make your code changes  
# 2. Rebuild the frontend image
docker build -f Dockerfile.frontend -t gmail-frontend:latest .

# 3. Restart the frontend deployment
kubectl rollout restart deployment/frontend-deployment -n gmail-upload

# 4. Wait for rollout to complete
kubectl rollout status deployment/frontend-deployment -n gmail-upload
```

## 🔧 **Useful Management Commands**

### Viewing Logs
```bash
# Backend logs
kubectl logs deployment/backend-deployment -n gmail-upload -f

# Frontend logs
kubectl logs deployment/frontend-deployment -n gmail-upload -f

# All logs (in separate terminals)
kubectl logs -f -l app=backend -n gmail-upload
kubectl logs -f -l app=frontend -n gmail-upload
```

### Checking Application Status
```bash
# Check all resources
kubectl get all -n gmail-upload

# Check pod details
kubectl describe pods -n gmail-upload

# Check services
kubectl get services -n gmail-upload

# Check persistent volumes
kubectl get pv,pvc -n gmail-upload
```

### Scaling Your Application
```bash
# Scale backend to 2 replicas
kubectl scale deployment backend-deployment --replicas=2 -n gmail-upload

# Scale frontend to 2 replicas
kubectl scale deployment frontend-deployment --replicas=2 -n gmail-upload

# Check scaling status
kubectl get deployments -n gmail-upload
```

### Debugging Issues
```bash
# Get pod details for troubleshooting
kubectl describe pod <pod-name> -n gmail-upload

# Execute commands inside a pod
kubectl exec -it <pod-name> -n gmail-upload -- /bin/bash

# Check events for issues
kubectl get events -n gmail-upload --sort-by='.lastTimestamp'
```

## 🗂️ **Environment-Specific Deployments**

### Development Environment
```bash
# Use the existing manifests as-is for development
kubectl apply -f k8s/ -n gmail-upload
```

### Production Environment
Create separate manifests with production configurations:

```bash
# Create production directory
mkdir k8s-prod

# Copy and modify manifests for production:
# - Remove imagePullPolicy: Never
# - Use proper image tags (not :latest)
# - Add resource limits and requests
# - Configure proper secrets for sensitive data
# - Use LoadBalancer service type instead of NodePort
```

## 📊 **Resource Management**

### Monitoring Resource Usage
```bash
# Check resource usage
kubectl top pods -n gmail-upload
kubectl top nodes

# Check resource requests and limits
kubectl describe deployments -n gmail-upload
```

### Setting Resource Limits (Recommended for Production)
Edit your deployment manifests to include:

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

## 🛡️ **Security Considerations**

### For Production Deployments:
1. **Create proper secrets for sensitive data**:
```bash
kubectl create secret generic app-secrets \
  --from-literal=secret-key=your-secret-key \
  -n gmail-upload
```

2. **Use specific image tags instead of :latest**
3. **Implement network policies**
4. **Set up proper RBAC**
5. **Use non-root containers**

## 🧹 **Cleanup**

### Remove Application
```bash
# Delete all application resources
kubectl delete -f k8s/ -n gmail-upload

# Or delete namespace (removes everything)
kubectl delete namespace gmail-upload

# Remove Docker images (optional)
docker rmi gmail-backend:latest gmail-frontend:latest
```

### Stop Minikube
```bash
# Stop Minikube cluster
minikube stop

# Delete Minikube cluster (removes everything)
minikube delete
```

## 🔄 **Update Workflow**

### Complete Update Process:
```bash
# 1. Pull latest code changes
# git pull origin main

# 2. Build new images
docker build -f Dockerfile.backend -t gmail-backend:v1.1 .
docker build -f Dockerfile.frontend -t gmail-frontend:v1.1 .

# 3. Update image tags in deployment manifests
# Edit k8s/backend-deployment.yaml and k8s/frontend-deployment.yaml
# Change: image: gmail-backend:latest
# To: image: gmail-backend:v1.1

# 4. Apply updates
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/frontend-deployment.yaml

# 5. Watch rollout
kubectl rollout status deployment/backend-deployment -n gmail-upload
kubectl rollout status deployment/frontend-deployment -n gmail-upload
```

## 📈 **Production Deployment Checklist**

- [ ] Use specific image tags (not :latest)
- [ ] Set resource requests and limits
- [ ] Configure health checks
- [ ] Set up proper secrets management
- [ ] Configure ingress for external access
- [ ] Set up monitoring and logging
- [ ] Configure backup for persistent volumes
- [ ] Implement proper RBAC
- [ ] Set up network policies
- [ ] Configure horizontal pod autoscaling

## 🎯 **Key Differences from DevSpace**

| Feature | Manual Deployment | DevSpace |
|---------|------------------|----------|
| **Image Building** | Manual `docker build` | Automatic |
| **Hot Reloading** | Manual rebuild + restart | Automatic sync |
| **Port Forwarding** | Manual `kubectl port-forward` | Automatic |
| **Logs** | Manual `kubectl logs` | Integrated viewer |
| **File Sync** | Not available | Real-time sync |
| **Debugging** | Manual kubectl commands | Integrated tools |
| **Setup Complexity** | Higher | Lower |
| **Control** | Full control | Abstracted |
| **Production Ready** | Yes (with proper config) | Development focused |

## 🚀 **Quick Commands Reference**

```bash
# Build images
docker build -f Dockerfile.backend -t gmail-backend:latest .
docker build -f Dockerfile.frontend -t gmail-frontend:latest .

# Deploy
kubectl apply -f k8s/

# Access application
kubectl port-forward service/frontend-service 5001:5001 -n gmail-upload

# View logs
kubectl logs deployment/backend-deployment -n gmail-upload -f

# Update application
kubectl rollout restart deployment/backend-deployment -n gmail-upload

# Check status
kubectl get all -n gmail-upload

# Cleanup
kubectl delete namespace gmail-upload
```

This manual approach gives you complete control over your Kubernetes deployment and is suitable for production environments where you need precise control over the deployment process. 