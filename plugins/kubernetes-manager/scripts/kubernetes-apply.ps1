param(
  [string]$Path = "k8s",
  [switch]$UseKustomize,
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

$targetFlag = if ($UseKustomize) { "-k" } else { "-f" }

Write-Host "Validating Kubernetes manifests at $Path"
kubectl apply --dry-run=client $targetFlag $Path

if (-not $SkipDiff) {
  Write-Host "Showing cluster diff"
  kubectl diff $targetFlag $Path
}

if ($Apply) {
  Write-Host "Applying Kubernetes manifests"
  kubectl apply $targetFlag $Path
} else {
  Write-Host "Dry run complete. Re-run with -Apply to apply changes."
}
