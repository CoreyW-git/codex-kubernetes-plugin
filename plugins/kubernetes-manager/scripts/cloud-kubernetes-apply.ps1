param(
  [string]$Path = "k8s",
  [switch]$UseKustomize,
  [string]$ExpectedContext,
  [string]$Namespace,
  [switch]$Apply,
  [switch]$SkipDiff
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
  throw "kubectl was not found on PATH."
}

if (-not (Test-Path $Path)) {
  throw "Path not found: $Path"
}

$currentContext = kubectl config current-context
if ($currentContext -eq "docker-desktop") {
  throw "Current context is docker-desktop. Switch to the intended cloud cluster before cloud deployment."
}

if ($ExpectedContext -and $currentContext -ne $ExpectedContext) {
  throw "Current context '$currentContext' does not match expected context '$ExpectedContext'."
}

$targetFlag = if ($UseKustomize) { "-k" } else { "-f" }
$namespaceArgs = @()
if ($Namespace) {
  $namespaceArgs = @("--namespace", $Namespace)
}

Write-Host "Cloud deployment target context: $currentContext"
if ($Namespace) {
  Write-Host "Namespace: $Namespace"
}

Write-Host "Validating Kubernetes manifests at $Path"
kubectl apply --dry-run=client $targetFlag $Path @namespaceArgs

if (-not $SkipDiff) {
  Write-Host "Showing cluster diff"
  kubectl diff $targetFlag $Path @namespaceArgs
}

if ($Apply) {
  Write-Host "Applying Kubernetes manifests"
  kubectl apply $targetFlag $Path @namespaceArgs
} else {
  Write-Host "Dry run complete. Re-run with -Apply to apply changes."
}
