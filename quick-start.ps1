# Gmail File Upload - Quick Start Script for Windows
# This script helps you get everything running quickly

Write-Host "🚀 Gmail File Upload - Kubernetes Deployment Setup" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Check if Minikube is installed
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
try {
    $minikubeVersion = minikube version 2>$null
    Write-Host "✅ Minikube is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Minikube is not installed. Please install it first:" -ForegroundColor Red
    Write-Host "   choco install minikube" -ForegroundColor White
    exit 1
}

# Check if kubectl is installed
try {
    $kubectlVersion = kubectl version --client 2>$null
    Write-Host "✅ kubectl is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ kubectl is not installed. Please install it first:" -ForegroundColor Red
    Write-Host "   choco install kubernetes-cli" -ForegroundColor White
    exit 1
}

# Check if DevSpace is installed
try {
    $devspaceVersion = devspace version 2>$null
    Write-Host "✅ DevSpace is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ DevSpace is not installed. Please install it first:" -ForegroundColor Red
    Write-Host "   See K8S_DEPLOYMENT_GUIDE.md for installation instructions" -ForegroundColor White
    exit 1
}

# Check if Docker is running
try {
    docker info 2>$null | Out-Null
    Write-Host "✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not running. Please start Docker Desktop" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Starting Minikube..." -ForegroundColor Yellow
minikube start --driver=docker

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Minikube started successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to start Minikube" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Configuring Docker environment..." -ForegroundColor Yellow
& minikube -p minikube docker-env --shell powershell | Invoke-Expression

Write-Host ""
Write-Host "Deploying application..." -ForegroundColor Yellow
devspace deploy

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Application deployed successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to deploy application" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Setup completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Run 'devspace dev' to start development mode with hot reloading" -ForegroundColor White
Write-Host "2. Access your app at http://localhost:5001" -ForegroundColor White
Write-Host "3. Check the API docs at http://localhost:8000/docs" -ForegroundColor White
Write-Host ""
Write-Host "For more information, see K8S_DEPLOYMENT_GUIDE.md" -ForegroundColor Yellow 