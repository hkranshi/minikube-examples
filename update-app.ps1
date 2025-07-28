# Gmail File Upload - Update Application Script
# This script rebuilds and updates your Kubernetes deployment when you make code changes

param(
    [string]$Component = "all",  # "backend", "frontend", or "all"
    [string]$Version = "latest"
)

Write-Host "🔄 Gmail File Upload - Update Application" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

if ($Component -ne "all" -and $Component -ne "backend" -and $Component -ne "frontend") {
    Write-Host "❌ Invalid component. Use: 'backend', 'frontend', or 'all'" -ForegroundColor Red
    Write-Host "Usage: .\update-app.ps1 -Component all -Version latest" -ForegroundColor Yellow
    exit 1
}

# Check if Minikube is running
Write-Host "Checking Minikube status..." -ForegroundColor Yellow
try {
    $minikubeStatus = minikube status 2>$null
    if ($minikubeStatus -like "*Running*") {
        Write-Host "✅ Minikube is running" -ForegroundColor Green
    } else {
        Write-Host "❌ Minikube is not running. Please start it first:" -ForegroundColor Red
        Write-Host "   minikube start --driver=docker" -ForegroundColor White
        exit 1
    }
} catch {
    Write-Host "❌ Could not check Minikube status" -ForegroundColor Red
    exit 1
}

# Configure Docker environment
Write-Host "Configuring Docker environment..." -ForegroundColor Yellow
& minikube -p minikube docker-env --shell powershell | Invoke-Expression

function Update-Component {
    param(
        [string]$ComponentName,
        [string]$ImageTag
    )
    
    Write-Host ""
    Write-Host "Updating $ComponentName..." -ForegroundColor Cyan
    
    # Build new image
    Write-Host "Building new $ComponentName image..." -ForegroundColor White
    if ($ComponentName -eq "backend") {
        docker build -f Dockerfile.backend -t gmail-backend:$ImageTag .
    } else {
        docker build -f Dockerfile.frontend -t gmail-frontend:$ImageTag .
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to build $ComponentName image" -ForegroundColor Red
        return $false
    }
    
    Write-Host "✅ $ComponentName image built successfully" -ForegroundColor Green
    
    # Restart deployment
    Write-Host "Restarting $ComponentName deployment..." -ForegroundColor White
    kubectl rollout restart deployment/$ComponentName-deployment -n gmail-upload
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to restart $ComponentName deployment" -ForegroundColor Red
        return $false
    }
    
    # Wait for rollout to complete
    Write-Host "Waiting for $ComponentName rollout to complete..." -ForegroundColor White
    kubectl rollout status deployment/$ComponentName-deployment -n gmail-upload --timeout=300s
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ $ComponentName rollout failed or timed out" -ForegroundColor Red
        return $false
    }
    
    Write-Host "✅ $ComponentName updated successfully!" -ForegroundColor Green
    return $true
}

# Update components based on parameter
$success = $true

if ($Component -eq "all" -or $Component -eq "backend") {
    $success = Update-Component -ComponentName "backend" -ImageTag $Version
    if (-not $success) {
        Write-Host "❌ Backend update failed" -ForegroundColor Red
        exit 1
    }
}

if ($Component -eq "all" -or $Component -eq "frontend") {
    $success = Update-Component -ComponentName "frontend" -ImageTag $Version
    if (-not $success) {
        Write-Host "❌ Frontend update failed" -ForegroundColor Red
        exit 1
    }
}

# Show final status
Write-Host ""
Write-Host "📊 Final Deployment Status:" -ForegroundColor Cyan
kubectl get pods -n gmail-upload

Write-Host ""
Write-Host "🎉 Update completed successfully!" -ForegroundColor Green

# Check if port forwarding is needed
Write-Host ""
Write-Host "Checking if port forwarding is active..." -ForegroundColor Yellow

$frontendPortForward = Get-Process -Name "kubectl" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*port-forward*frontend-service*5001*" }
$backendPortForward = Get-Process -Name "kubectl" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*port-forward*backend-service*8000*" }

if (-not $frontendPortForward -and -not $backendPortForward) {
    Write-Host ""
    Write-Host "💡 To access your updated application, set up port forwarding:" -ForegroundColor Yellow
    Write-Host "   kubectl port-forward service/frontend-service 5001:5001 -n gmail-upload" -ForegroundColor Gray
    Write-Host "   kubectl port-forward service/backend-service 8000:8000 -n gmail-upload" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Would you like to set up port forwarding now? (y/n): " -NoNewline -ForegroundColor Cyan
    $response = Read-Host
    
    if ($response -eq "y" -or $response -eq "Y" -or $response -eq "yes") {
        Write-Host ""
        Write-Host "Setting up port forwarding..." -ForegroundColor Yellow
        
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
} else {
    Write-Host "✅ Port forwarding appears to be active" -ForegroundColor Green
    Write-Host "Your application should be accessible at:" -ForegroundColor White
    Write-Host "   Frontend: http://localhost:5001" -ForegroundColor Gray
    Write-Host "   Backend: http://localhost:8000" -ForegroundColor Gray
} 