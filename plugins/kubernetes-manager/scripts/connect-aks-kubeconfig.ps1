param(
  [Parameter(Mandatory = $true)]
  [string]$ResourceGroup,

  [Parameter(Mandatory = $true)]
  [string]$ClusterName,

  [string]$ContextName,
  [string]$KubeconfigPath,
  [switch]$Admin,
  [switch]$OverwriteExisting
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  throw "Azure CLI was not found on PATH."
}

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
  throw "kubectl was not found on PATH."
}

$argsList = @(
  "aks", "get-credentials",
  "--resource-group", $ResourceGroup,
  "--name", $ClusterName
)

if ($ContextName) {
  $argsList += @("--context", $ContextName)
}

if ($KubeconfigPath) {
  $argsList += @("--file", $KubeconfigPath)
}

if ($Admin) {
  $argsList += "--admin"
}

if ($OverwriteExisting) {
  $argsList += "--overwrite-existing"
}

Write-Host "Writing AKS kubeconfig for cluster $ClusterName"
& az @argsList

Write-Host "Current kubectl context:"
kubectl config current-context
kubectl get nodes
