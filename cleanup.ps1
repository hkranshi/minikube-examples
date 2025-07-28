# Gmail File Upload - Cleanup Script
# This script removes all deployed resources and optionally stops Minikube

param(
    [switch]$StopMinikube = $false,
    [switch]$DeleteMinikube = $false,
    [switch]$RemoveImages = $false
)

Write-Host "🧹 Gmail File Upload - Cleanup" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan

Write-Host ""
Write-Host "This will remove all deployed Gmail File Upload resources." -ForegroundColor Yellow
Write-Host "Cleanup options:" -ForegroundColor White
Write-Host "- Application resources: ✅ Will be removed" -ForegroundColor White
if ($StopMinikube) {
    Write-Host "- Stop Minikube: ✅ Will stop Minikube cluster" -ForegroundColor White
}
if ($DeleteMinikube) {
    Write-Host "- Delete Minikube: ✅ Will completely delete Minikube cluster" -ForegroundColor Red
}
if ($RemoveImages) {
    Write-Host "- Remove Docker images: ✅ Will remove Gmail app images" -ForegroundColor White
}

Write-Host ""
Write-Host "Are you sure you want to proceed? (y/n): " -NoNewline -ForegroundColor Red
$confirmation = Read-Host

if ($confirmation -ne "y" -and $confirmation -ne "Y" -and $confirmation -ne "yes") {
    Write-Host "Cleanup cancelled." -ForegroundColor Yellow
    exit 0
}

# Stop any existing port forwarding
Write-Host ""
Write-Host "Stopping port forwarding..." -ForegroundColor Yellow
Get-Job -Name "*port-forward*" -ErrorAction SilentlyContinue | Stop-Job
Get-Job -Name "*port-forward*" -ErrorAction SilentlyContinue | Remove-Job
Write-Host "✅ Port forwarding stopped" -ForegroundColor Green

# Remove application resources
Write-Host ""
Write-Host "Removing application resources..." -ForegroundColor Yellow

# Check if namespace exists
$namespaceExists = kubectl get namespace gmail-upload 2>$null
if ($namespaceExists) {
    Write-Host "Removing Gmail File Upload application..." -ForegroundColor White
    
    # Delete all resources in the namespace
    kubectl delete all --all -n gmail-upload
    kubectl delete pvc --all -n gmail-upload
    kubectl delete pv uploads-pv
    kubectl delete namespace gmail-upload
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Application resources removed successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Some resources may not have been removed completely" -ForegroundColor Yellow
    }
} else {
    Write-Host "ℹ️  No Gmail File Upload resources found to remove" -ForegroundColor Blue
}

# Remove Docker images if requested
if ($RemoveImages) {
    Write-Host ""
    Write-Host "Removing Docker images..." -ForegroundColor Yellow
    
    # Configure Docker to use Minikube's daemon if Minikube is running
    try {
        $minikubeStatus = minikube status 2>$null
        if ($minikubeStatus -like "*Running*") {
            & minikube -p minikube docker-env --shell powershell | Invoke-Expression
        }
    } catch {
        # Minikube might not be running, continue anyway
    }
    
    $backendImage = docker images gmail-backend --format "table {{.Repository}}:{{.Tag}}" 2>$null
    $frontendImage = docker images gmail-frontend --format "table {{.Repository}}:{{.Tag}}" 2>$null
    
    if ($backendImage -and $backendImage -ne "REPOSITORY:TAG") {
        docker rmi gmail-backend:latest -f 2>$null
        Write-Host "✅ Backend image removed" -ForegroundColor Green
    }
    
    if ($frontendImage -and $frontendImage -ne "REPOSITORY:TAG") {
        docker rmi gmail-frontend:latest -f 2>$null
        Write-Host "✅ Frontend image removed" -ForegroundColor Green
    }
    
    if (-not $backendImage -and -not $frontendImage) {
        Write-Host "ℹ️  No Gmail app images found to remove" -ForegroundColor Blue
    }
}

# Stop or delete Minikube if requested
if ($DeleteMinikube) {
    Write-Host ""
    Write-Host "Deleting Minikube cluster..." -ForegroundColor Red
    Write-Host "⚠️  This will completely remove your Minikube cluster!" -ForegroundColor Yellow
    Write-Host "Are you absolutely sure? (type 'DELETE' to confirm): " -NoNewline -ForegroundColor Red
    $deleteConfirmation = Read-Host
    
    if ($deleteConfirmation -eq "DELETE") {
        minikube delete
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Minikube cluster deleted completely" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to delete Minikube cluster" -ForegroundColor Red
        }
    } else {
        Write-Host "Minikube deletion cancelled" -ForegroundColor Yellow
    }
} elseif ($StopMinikube) {
    Write-Host ""
    Write-Host "Stopping Minikube..." -ForegroundColor Yellow
    minikube stop
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Minikube stopped successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to stop Minikube" -ForegroundColor Red
    }
}

# Show final status
Write-Host ""
Write-Host "🎉 Cleanup completed!" -ForegroundColor Green

# Show what remains
Write-Host ""
Write-Host "Current status:" -ForegroundColor Cyan

try {
    $minikubeStatus = minikube status 2>$null
    if ($minikubeStatus -like "*Running*") {
        Write-Host "- Minikube: ✅ Running" -ForegroundColor Green
        
        # Check for any remaining namespaces
        $namespaces = kubectl get namespaces --no-headers 2>$null | ForEach-Object { ($_ -split '\s+')[0] }
        $appNamespaces = $namespaces | Where-Object { $_ -like "*gmail*" -or $_ -like "*upload*" }
        
        if ($appNamespaces) {
            Write-Host "- Remaining app namespaces: $($appNamespaces -join ', ')" -ForegroundColor Yellow
        } else {
            Write-Host "- Gmail app resources: ✅ All cleaned up" -ForegroundColor Green
        }
    } elseif ($minikubeStatus -like "*Stopped*") {
        Write-Host "- Minikube: ⏹️  Stopped" -ForegroundColor Yellow
    } else {
        Write-Host "- Minikube: ❌ Not found or deleted" -ForegroundColor Red
    }
} catch {
    Write-Host "- Minikube: ❌ Not available" -ForegroundColor Red
}

# Show next steps
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
if (-not $DeleteMinikube) {
    Write-Host "- To redeploy: Run .\manual-deploy.ps1" -ForegroundColor White
    Write-Host "- To start Minikube: minikube start --driver=docker" -ForegroundColor White
}
Write-Host "- To check status: kubectl get all --all-namespaces" -ForegroundColor White

Write-Host ""
Write-Host "Cleanup summary:" -ForegroundColor Cyan
Write-Host "- Application resources: Removed ✅" -ForegroundColor White
if ($RemoveImages) {
    Write-Host "- Docker images: Removed ✅" -ForegroundColor White
}
if ($StopMinikube) {
    Write-Host "- Minikube: Stopped ⏹️" -ForegroundColor White
}
if ($DeleteMinikube) {
    Write-Host "- Minikube: Deleted ❌" -ForegroundColor White
}

Write-Host ""
Write-Host "Goodbye! 👋" -ForegroundColor Green 