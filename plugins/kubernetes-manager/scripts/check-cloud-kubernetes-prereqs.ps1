param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("OKE", "AKS", "AKE")]
  [string]$Provider
)

$ErrorActionPreference = "Stop"

function Test-Command {
  param([string]$Name)
  $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

if (-not (Test-Command "kubectl")) {
  throw "kubectl was not found on PATH."
}

switch ($Provider) {
  "OKE" {
    if (-not (Test-Command "oci")) {
      throw "OCI CLI was not found on PATH. Install and configure OCI CLI before connecting to OKE."
    }
    Write-Host "OCI CLI:"
    oci --version
    Write-Host "OCI config profiles:"
    oci setup config --help | Select-Object -First 1 | Out-Host
  }
  { $_ -in @("AKS", "AKE") } {
    if (-not (Test-Command "az")) {
      throw "Azure CLI was not found on PATH. Install Azure CLI and run az login before connecting to AKS."
    }
    Write-Host "Azure CLI:"
    az version --query '"azure-cli"' -o tsv
    Write-Host "Azure account:"
    az account show --query '{name:name, subscription:id, tenant:tenantId}' -o table
  }
}

Write-Host "kubectl:"
kubectl version --client
Write-Host "Current context:"
kubectl config current-context
