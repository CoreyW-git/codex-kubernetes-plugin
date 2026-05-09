param(
  [Parameter(Mandatory = $true)]
  [string]$ClusterId,

  [Parameter(Mandatory = $true)]
  [string]$Region,

  [ValidateSet("PUBLIC_ENDPOINT", "PRIVATE_ENDPOINT", "VCN_HOSTNAME", "LEGACY_KUBERNETES")]
  [string]$KubeEndpoint = "PUBLIC_ENDPOINT",

  [string]$KubeconfigPath = "$HOME\.kube\config",
  [string]$Profile,
  [switch]$Overwrite
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command oci -ErrorAction SilentlyContinue)) {
  throw "OCI CLI was not found on PATH."
}

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
  throw "kubectl was not found on PATH."
}

$argsList = @(
  "ce", "cluster", "create-kubeconfig",
  "--cluster-id", $ClusterId,
  "--file", $KubeconfigPath,
  "--region", $Region,
  "--token-version", "2.0.0",
  "--kube-endpoint", $KubeEndpoint
)

if ($Profile) {
  $argsList += @("--profile", $Profile)
}

if ($Overwrite) {
  $argsList += "--overwrite"
}

Write-Host "Writing OKE kubeconfig for cluster $ClusterId"
& oci @argsList

Write-Host "Current kubectl context:"
kubectl config current-context
kubectl get nodes
