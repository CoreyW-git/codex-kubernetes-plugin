param(
  [switch]$SwitchContext
)

$ErrorActionPreference = "Stop"

function Test-Command {
  param([string]$Name)
  $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

Write-Host "Kubernetes Manager: Docker Desktop Kubernetes check"

if (-not (Test-Command "docker")) {
  throw "docker was not found on PATH. Install or start Docker Desktop."
}

if (-not (Test-Command "kubectl")) {
  throw "kubectl was not found on PATH. Enable Kubernetes in Docker Desktop or install kubectl."
}

$dockerVersion = docker version --format "{{.Server.Version}}" 2>$null
if (-not $dockerVersion) {
  throw "Docker Desktop does not appear to be running."
}
Write-Host "Docker server: $dockerVersion"

$contexts = kubectl config get-contexts -o name
if ($contexts -notcontains "docker-desktop") {
  throw "The docker-desktop Kubernetes context was not found. Enable Kubernetes in Docker Desktop settings."
}

$currentContext = kubectl config current-context
Write-Host "Current kubectl context: $currentContext"

if ($currentContext -ne "docker-desktop") {
  if ($SwitchContext) {
    kubectl config use-context docker-desktop | Out-Host
  } else {
    Write-Warning "Run with -SwitchContext to switch kubectl to docker-desktop."
  }
}

kubectl get nodes
