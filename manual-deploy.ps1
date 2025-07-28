# Gmail File Upload - Manual Kubernetes Deployment Script
# This script deploys your application to Kubernetes without DevSpace

Write-Host "🐳 Gmail File Upload - Manual Kubernetes Deployment" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

try {
    $dockerVersion = docker --version 2>$null
    Write-Host "✅ Docker is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

try {
    docker info 2>$null | Out-Null
    Write-Host "✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not running. Please start Docker Desktop" -ForegroundColor Red
    exit 1
}

try {
    $minikubeVersion = minikube version 2>$null
    Write-Host "✅ Minikube is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Minikube is not installed" -ForegroundColor Red
    Write-Host "   Install with: choco install minikube" -ForegroundColor White
    exit 1
}

try {
    $kubectlVersion = kubectl version --client 2>$null
    Write-Host "✅ kubectl is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ kubectl is not installed" -ForegroundColor Red
    Write-Host "   Install with: choco install kubernetes-cli" -ForegroundColor White
    exit 1
}

# Start Minikube
Write-Host ""
Write-Host "Starting Minikube..." -ForegroundColor Yellow
minikube start --driver=docker

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to start Minikube" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Minikube started successfully" -ForegroundColor Green

# Configure Docker environment
Write-Host ""
Write-Host "Configuring Docker environment for Minikube..." -ForegroundColor Yellow
& minikube -p minikube docker-env --shell powershell | Invoke-Expression
Write-Host "✅ Docker environment configured" -ForegroundColor Green

# Build Docker images
Write-Host ""
Write-Host "Building Docker images..." -ForegroundColor Yellow

Write-Host "Building backend image..." -ForegroundColor White
docker build -f Dockerfile.backend -t gmail-backend:latest .

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to build backend image" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Backend image built successfully" -ForegroundColor Green

Write-Host "Building frontend image..." -ForegroundColor White
docker build -f Dockerfile.frontend -t gmail-frontend:latest .

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to build frontend image" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Frontend image built successfully" -ForegroundColor Green

# Deploy to Kubernetes
Write-Host ""
Write-Host "Deploying to Kubernetes..." -ForegroundColor Yellow

Write-Host "Creating namespace..." -ForegroundColor White
kubectl apply -f k8s/namespace.yaml

Write-Host "Setting up persistent storage..." -ForegroundColor White
kubectl apply -f k8s/persistent-volume.yaml

Write-Host "Deploying backend service..." -ForegroundColor White
kubectl apply -f k8s/backend-deployment.yaml

Write-Host "Deploying frontend service..." -ForegroundColor White
kubectl apply -f k8s/frontend-deployment.yaml

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to deploy to Kubernetes" -ForegroundColor Red
    exit 1
}

Write-Host "✅ All services deployed successfully" -ForegroundColor Green

# Wait for pods to be ready
Write-Host ""
Write-Host "Waiting for pods to be ready..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor White

$timeout = 300  # 5 minutes timeout
$elapsed = 0
$interval = 10

do {
    Start-Sleep -Seconds $interval
    $elapsed += $interval
    
    $pods = kubectl get pods -n gmail-upload --no-headers 2>$null
    if ($pods) {
        $readyPods = ($pods | Where-Object { $_ -match "Running" }).Count
        $totalPods = ($pods | Measure-Object).Count
        
        Write-Host "Pods ready: $readyPods/$totalPods" -ForegroundColor White
        
        if ($readyPods -eq $totalPods -and $totalPods -gt 0) {
            break
        }
    }
    
    if ($elapsed -ge $timeout) {
        Write-Host "❌ Timeout waiting for pods to be ready" -ForegroundColor Red
        Write-Host "Check pod status with: kubectl get pods -n gmail-upload" -ForegroundColor Yellow
        exit 1
    }
} while ($true)

Write-Host "✅ All pods are ready!" -ForegroundColor Green

# Show deployment status
Write-Host ""
Write-Host "Deployment Status:" -ForegroundColor Cyan
kubectl get all -n gmail-upload

Write-Host ""
Write-Host "🎉 Deployment completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Set up port forwarding to access your application:" -ForegroundColor White
Write-Host "   kubectl port-forward service/frontend-service 5001:5001 -n gmail-upload" -ForegroundColor Gray
Write-Host ""
Write-Host "2. In a separate terminal, forward the backend port:" -ForegroundColor White
Write-Host "   kubectl port-forward service/backend-service 8000:8000 -n gmail-upload" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Access your application:" -ForegroundColor White
Write-Host "   Frontend: http://localhost:5001" -ForegroundColor Gray
Write-Host "   Backend API: http://localhost:8000/docs" -ForegroundColor Gray
Write-Host ""
Write-Host "4. View logs:" -ForegroundColor White
Write-Host "   kubectl logs deployment/backend-deployment -n gmail-upload -f" -ForegroundColor Gray
Write-Host "   kubectl logs deployment/frontend-deployment -n gmail-upload -f" -ForegroundColor Gray
Write-Host ""
Write-Host "For detailed instructions, see MANUAL_K8S_DEPLOYMENT.md" -ForegroundColor Yellow

Write-Host ""
Write-Host "Would you like to set up port forwarding now? (y/n): " -NoNewline -ForegroundColor Cyan
$response = Read-Host

if ($response -eq "y" -or $response -eq "Y" -or $response -eq "yes") {
    Write-Host ""
    Write-Host "Setting up port forwarding..." -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop port forwarding when you're done" -ForegroundColor White
    Write-Host ""
    
    # Start port forwarding in background jobs
    Start-Job -ScriptBlock { kubectl port-forward service/frontend-service 5001:5001 -n gmail-upload } -Name "frontend-port-forward"
    Start-Job -ScriptBlock { kubectl port-forward service/backend-service 8000:8000 -n gmail-upload } -Name "backend-port-forward"
    
    Start-Sleep -Seconds 3
    
    Write-Host "✅ Port forwarding is now active!" -ForegroundColor Green
    Write-Host "Frontend: http://localhost:5001" -ForegroundColor White
    Write-Host "Backend: http://localhost:8000" -ForegroundColor White
    Write-Host ""
    Write-Host "Press any key to stop port forwarding and exit..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    # Stop background jobs
    Stop-Job -Name "frontend-port-forward" -ErrorAction SilentlyContinue
    Stop-Job -Name "backend-port-forward" -ErrorAction SilentlyContinue
    Remove-Job -Name "frontend-port-forward" -ErrorAction SilentlyContinue
    Remove-Job -Name "backend-port-forward" -ErrorAction SilentlyContinue
    
    Write-Host ""
    Write-Host "Port forwarding stopped. Goodbye! 👋" -ForegroundColor Green
} 