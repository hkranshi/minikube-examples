# 🚀 Gmail File Upload - Kubernetes Deployment with DevSpace

This guide will help you deploy your Gmail file upload application on Minikube using DevSpace for hot reloading. Perfect for developers with no Kubernetes experience!

## 📋 **What You'll Learn**

- How to set up Minikube (local Kubernetes)
- How to use DevSpace for easy development
- How hot reloading works in Kubernetes
- How to access your app from localhost
- How to debug and troubleshoot

## 🛠️ **Prerequisites**

### 1. Install Docker Desktop
```bash
# Download Docker Desktop from: https://www.docker.com/products/docker-desktop/
# Make sure Docker is running (you should see the Docker icon in your system tray)
```

### 2. Install Minikube
```bash
# Windows (using Chocolatey - install Chocolatey first if you don't have it)
choco install minikube

# Alternative: Download directly from https://minikube.sigs.k8s.io/docs/start/
```

### 3. Install kubectl (Kubernetes CLI)
```bash
# Windows (using Chocolatey)
choco install kubernetes-cli

# Alternative: Download from https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
```

### 4. Install DevSpace
```bash
# Windows (using PowerShell as Administrator)
iwr -useb https://github.com/loft-sh/devspace/releases/latest/download/devspace-windows-amd64.exe -outfile devspace.exe
mv devspace.exe C:\Windows\System32\devspace.exe

# Alternative: Download from https://devspace.sh/docs/getting-started/installation
```

## 🚀 **Step-by-Step Deployment**

### Step 1: Start Minikube
```bash
# Start Minikube with Docker driver
minikube start --driver=docker

# Verify Minikube is running
minikube status

# You should see something like:
# minikube
# type: Control Plane
# host: Running
# kubelet: Running
# apiserver: Running
# kubeconfig: Configured
```

### Step 2: Configure Docker Environment
```bash
# Point your Docker CLI to Minikube's Docker daemon
# This allows DevSpace to build images inside Minikube
minikube docker-env

# For Windows PowerShell, run:
& minikube -p minikube docker-env --shell powershell | Invoke-Expression
```

### Step 3: Navigate to Your Project
```bash
# Navigate to your project directory
cd "C:\Users\AnshikaSaxena\Downloads\gmail file upload\gmail file upload"
```

### Step 4: Deploy with DevSpace
```bash
# Initialize and deploy your application
devspace deploy

# This will:
# 1. Build Docker images for backend and frontend
# 2. Create Kubernetes namespace
# 3. Deploy all services
# 4. Set up persistent storage
```

### Step 5: Start Development Mode (Hot Reloading)
```bash
# Start DevSpace development mode
devspace dev

# This will:
# 1. Set up file synchronization
# 2. Enable port forwarding
# 3. Start hot reloading
# 4. Show logs from both services
```

## 🌐 **Accessing Your Application**

Once `devspace dev` is running, you can access your application:

### Frontend (Flask Web Interface)
- **URL**: http://localhost:5001
- **What it does**: Web interface for email validation and file uploads

### Backend (FastAPI)
- **URL**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health

## 🔥 **Hot Reloading in Action**

DevSpace automatically syncs your code changes to the running containers:

### Backend Changes (FastAPI)
1. Edit any file in `./app/` or `main.py`
2. Save the file
3. Changes are automatically synced to the container
4. Uvicorn reloads the server automatically
5. No need to restart anything!

### Frontend Changes (Flask)
1. Edit any file in `./frontend_flask/`
2. Save the file
3. Changes are automatically synced to the container
4. Flask reloads automatically in development mode
5. Refresh your browser to see changes

## 📁 **Project Structure After Setup**

```
gmail file upload/
├── app/                          # FastAPI backend code
├── frontend_flask/               # Flask frontend code
├── k8s/                          # Kubernetes manifests
│   ├── namespace.yaml
│   ├── persistent-volume.yaml
│   ├── backend-deployment.yaml
│   └── frontend-deployment.yaml
├── Dockerfile.backend            # Backend container definition
├── Dockerfile.frontend           # Frontend container definition
├── devspace.yaml                 # DevSpace configuration
├── main.py                       # FastAPI entry point
├── requirements.txt              # Backend dependencies
├── requirements_flask.txt        # Frontend dependencies
└── K8S_DEPLOYMENT_GUIDE.md      # This guide
```

## 🔧 **Useful Commands**

### DevSpace Commands
```bash
# Deploy application
devspace deploy

# Start development mode with hot reloading
devspace dev

# Show logs from backend
devspace run logs-backend

# Show logs from frontend
devspace run logs-frontend

# Show logs from all services
devspace run logs-all

# Clean up everything
devspace purge
```

### Kubernetes Commands
```bash
# Check if pods are running
kubectl get pods -n gmail-upload

# Check services
kubectl get services -n gmail-upload

# Describe a pod (for troubleshooting)
kubectl describe pod <pod-name> -n gmail-upload

# Get pod logs manually
kubectl logs <pod-name> -n gmail-upload -f
```

### Minikube Commands
```bash
# Check Minikube status
minikube status

# Open Kubernetes dashboard
minikube dashboard

# Stop Minikube
minikube stop

# Start Minikube
minikube start
```

## 🐛 **Troubleshooting**

### Problem: "No space left on device"
```bash
# Clean up Docker images in Minikube
minikube ssh -- docker system prune -a -f
```

### Problem: "Image pull policy Never"
```bash
# Make sure you're using Minikube's Docker daemon
& minikube -p minikube docker-env --shell powershell | Invoke-Expression
```

### Problem: "Connection refused to backend"
```bash
# Check if backend pod is running
kubectl get pods -n gmail-upload

# Check backend service
kubectl get services -n gmail-upload

# Check logs
kubectl logs deployment/backend-deployment -n gmail-upload
```

### Problem: "Can't access from localhost"
```bash
# Make sure DevSpace is running with port forwarding
devspace dev

# Alternative: Manual port forwarding
kubectl port-forward service/frontend-service 5001:5001 -n gmail-upload
```

### Problem: Changes not reflecting
1. Make sure `devspace dev` is running
2. Check file sync status in DevSpace output
3. Verify the container is rebuilding (you'll see output in terminal)

## 📊 **Understanding the Architecture**

### In Kubernetes:
- **Namespace**: `gmail-upload` - Isolated environment for your app
- **Backend Pod**: Runs FastAPI server (port 8000)
- **Frontend Pod**: Runs Flask server (port 5001)
- **Persistent Volume**: Shared storage for uploaded files
- **Services**: Network endpoints for pod communication

### DevSpace Magic:
- **File Sync**: Copies your local changes to containers
- **Port Forwarding**: Makes container ports accessible on localhost
- **Hot Reloading**: Automatically restarts services when code changes
- **Image Building**: Builds Docker images in Minikube's environment

## 🎯 **Development Workflow**

1. **Start**: `devspace dev`
2. **Code**: Edit files in your local editor
3. **Save**: Changes automatically sync to containers
4. **Test**: App reloads automatically
5. **Debug**: Check logs in DevSpace terminal
6. **Repeat**: Continue coding without restarts!

## 🚪 **When You're Done**

```bash
# Stop development mode (Ctrl+C in DevSpace terminal)

# Clean up all resources
devspace purge

# Stop Minikube (optional)
minikube stop
```

## 🎉 **Success Indicators**

You'll know everything is working when:
- ✅ `devspace dev` starts without errors
- ✅ You can access http://localhost:5001 in your browser
- ✅ You can validate Gmail addresses and upload files
- ✅ Code changes appear automatically when you save files
- ✅ Both services show "healthy" status

Happy coding! 🚀 