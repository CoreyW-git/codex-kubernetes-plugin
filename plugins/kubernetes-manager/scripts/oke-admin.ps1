param(
  [Parameter(Mandatory = $true)]
  [ValidateSet(
    "ListClusters",
    "ShowCluster",
    "DeleteCluster",
    "ListAddons",
    "ListNodePools",
    "ShowNodePool",
    "DeleteNodePool",
    "DeleteNode",
    "ListWorkRequests",
    "ShowWorkRequest"
  )]
  [string]$Action,

  [string]$CompartmentId,
  [string]$ClusterId,
  [string]$NodePoolId,
  [string]$NodeId,
  [string]$WorkRequestId,
  [string]$Region,
  [string]$Profile,
  [switch]$Apply
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command oci -ErrorAction SilentlyContinue)) {
  throw "OCI CLI was not found on PATH."
}

function Add-OciGlobals {
  param([string[]]$ArgsList)
  if ($Region) { $ArgsList += @("--region", $Region) }
  if ($Profile) { $ArgsList += @("--profile", $Profile) }
  return $ArgsList
}

function Invoke-OciGuarded {
  param(
    [string[]]$ArgsList,
    [switch]$NeedsApply
  )

  $ArgsList = Add-OciGlobals $ArgsList
  Write-Host "oci $($ArgsList -join ' ')"
  if ($NeedsApply -and -not $Apply) {
    Write-Host "No changes made. Re-run with -Apply to execute this OKE administrative action."
    return
  }

  & oci @ArgsList
}

function Require-Compartment {
  if (-not $CompartmentId) { throw "-CompartmentId is required for action $Action." }
}

function Require-Cluster {
  if (-not $ClusterId) { throw "-ClusterId is required for action $Action." }
}

function Require-NodePool {
  if (-not $NodePoolId) { throw "-NodePoolId is required for action $Action." }
}

switch ($Action) {
  "ListClusters" { Require-Compartment; Invoke-OciGuarded @("ce", "cluster", "list", "--compartment-id", $CompartmentId, "--output", "table") }
  "ShowCluster" { Require-Cluster; Invoke-OciGuarded @("ce", "cluster", "get", "--cluster-id", $ClusterId) }
  "DeleteCluster" { Require-Cluster; Invoke-OciGuarded @("ce", "cluster", "delete", "--cluster-id", $ClusterId, "--force") -NeedsApply }
  "ListAddons" { Require-Cluster; Invoke-OciGuarded @("ce", "cluster", "list-addons", "--cluster-id", $ClusterId) }
  "ListNodePools" {
    Require-Compartment
    $argsList = @("ce", "node-pool", "list", "--compartment-id", $CompartmentId)
    if ($ClusterId) { $argsList += @("--cluster-id", $ClusterId) }
    $argsList += @("--output", "table")
    Invoke-OciGuarded $argsList
  }
  "ShowNodePool" { Require-NodePool; Invoke-OciGuarded @("ce", "node-pool", "get", "--node-pool-id", $NodePoolId) }
  "DeleteNodePool" { Require-NodePool; Invoke-OciGuarded @("ce", "node-pool", "delete", "--node-pool-id", $NodePoolId, "--force") -NeedsApply }
  "DeleteNode" {
    Require-NodePool
    if (-not $NodeId) { throw "-NodeId is required for DeleteNode." }
    Invoke-OciGuarded @("ce", "node-pool", "delete-node", "--node-pool-id", $NodePoolId, "--node-id", $NodeId, "--force") -NeedsApply
  }
  "ListWorkRequests" { Require-Compartment; Invoke-OciGuarded @("ce", "work-request", "list", "--compartment-id", $CompartmentId, "--output", "table") }
  "ShowWorkRequest" {
    if (-not $WorkRequestId) { throw "-WorkRequestId is required for ShowWorkRequest." }
    Invoke-OciGuarded @("ce", "work-request", "get", "--work-request-id", $WorkRequestId)
  }
}
