param(
  [Parameter(Mandatory = $true)]
  [string]$TargetProjectPath,

  [switch]$Force
)

$ErrorActionPreference = "Stop"

$pluginRoot = Split-Path -Parent $PSScriptRoot
$targetRoot = Resolve-Path -Path $TargetProjectPath
$targetPluginDir = Join-Path $targetRoot "plugins/kubernetes-manager"
$targetMarketplaceDir = Join-Path $targetRoot ".agents/plugins"
$targetMarketplacePath = Join-Path $targetMarketplaceDir "marketplace.json"

$sourceFullPath = [System.IO.Path]::GetFullPath($pluginRoot).TrimEnd('\')
$targetFullPath = [System.IO.Path]::GetFullPath($targetPluginDir).TrimEnd('\')

if ($sourceFullPath -eq $targetFullPath) {
  throw "Source and target plugin directories are the same. Nothing to install."
}

if ((Test-Path $targetPluginDir) -and -not $Force) {
  throw "Target plugin directory already exists: $targetPluginDir. Re-run with -Force to replace it."
}

if (Test-Path $targetPluginDir) {
  Remove-Item -Recurse -Force -Path $targetPluginDir
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $targetPluginDir) | Out-Null
Copy-Item -Recurse -Path $pluginRoot -Destination $targetPluginDir

New-Item -ItemType Directory -Force -Path $targetMarketplaceDir | Out-Null

$entry = [ordered]@{
  name = "kubernetes-manager"
  source = [ordered]@{
    source = "local"
    path = "./plugins/kubernetes-manager"
  }
  policy = [ordered]@{
    installation = "AVAILABLE"
    authentication = "ON_INSTALL"
  }
  category = "Developer Tools"
}

if (Test-Path $targetMarketplacePath) {
  $marketplace = Get-Content -Raw -Path $targetMarketplacePath | ConvertFrom-Json
  if (-not $marketplace.plugins) {
    $marketplace | Add-Member -NotePropertyName plugins -NotePropertyValue @()
  }
  $remaining = @($marketplace.plugins | Where-Object { $_.name -ne "kubernetes-manager" })
  $marketplace.plugins = @($remaining + [pscustomobject]$entry)
} else {
  $marketplace = [ordered]@{
    name = "local-plugins"
    interface = [ordered]@{
      displayName = "Local Plugins"
    }
    plugins = @([pscustomobject]$entry)
  }
}

$marketplace |
  ConvertTo-Json -Depth 10 |
  Set-Content -Path $targetMarketplacePath -Encoding utf8

Write-Host "Installed Kubernetes Manager into $targetRoot"
Write-Host "Plugin: $targetPluginDir"
Write-Host "Marketplace: $targetMarketplacePath"
