param(
  [Parameter(Mandatory = $true)]
  [ValidateSet(
    "ListClusters",
    "ShowCluster",
    "StartCluster",
    "StopCluster",
    "ScaleCluster",
    "ListNodePools",
    "ShowNodePool",
    "ScaleNodePool",
    "StartNodePool",
    "StopNodePool",
    "DeleteNodePool"
  )]
  [string]$Action,

  [string]$ResourceGroup,
  [string]$ClusterName,
  [string]$NodePoolName,
  [int]$NodeCount,
  [switch]$NoWait,
  [switch]$Apply
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  throw "Azure CLI was not found on PATH."
}

function Invoke-AzGuarded {
  param(
    [string[]]$ArgsList,
    [switch]$NeedsApply
  )

  Write-Host "az $($ArgsList -join ' ')"
  if ($NeedsApply -and -not $Apply) {
    Write-Host "No changes made. Re-run with -Apply to execute this AKS administrative action."
    return
  }

  & az @ArgsList
}

function Require-Cluster {
  if (-not $ResourceGroup) { throw "-ResourceGroup is required for action $Action." }
  if (-not $ClusterName) { throw "-ClusterName is required for action $Action." }
}

function Require-NodePool {
  Require-Cluster
  if (-not $NodePoolName) { throw "-NodePoolName is required for action $Action." }
}

$waitArgs = @()
if ($NoWait) { $waitArgs += "--no-wait" }

switch ($Action) {
  "ListClusters" {
    $argsList = @("aks", "list", "-o", "table")
    if ($ResourceGroup) { $argsList += @("--resource-group", $ResourceGroup) }
    Invoke-AzGuarded $argsList
  }
  "ShowCluster" { Require-Cluster; Invoke-AzGuarded @("aks", "show", "--resource-group", $ResourceGroup, "--name", $ClusterName, "-o", "table") }
  "StartCluster" { Require-Cluster; Invoke-AzGuarded (@("aks", "start", "--resource-group", $ResourceGroup, "--name", $ClusterName) + $waitArgs) -NeedsApply }
  "StopCluster" { Require-Cluster; Invoke-AzGuarded (@("aks", "stop", "--resource-group", $ResourceGroup, "--name", $ClusterName) + $waitArgs) -NeedsApply }
  "ScaleCluster" {
    Require-Cluster
    if ($PSBoundParameters.ContainsKey("NodeCount") -eq $false) { throw "-NodeCount is required for ScaleCluster." }
    $argsList = @("aks", "scale", "--resource-group", $ResourceGroup, "--name", $ClusterName, "--node-count", "$NodeCount") + $waitArgs
    if ($NodePoolName) { $argsList += @("--nodepool-name", $NodePoolName) }
    Invoke-AzGuarded $argsList -NeedsApply
  }
  "ListNodePools" { Require-Cluster; Invoke-AzGuarded @("aks", "nodepool", "list", "--resource-group", $ResourceGroup, "--cluster-name", $ClusterName, "-o", "table") }
  "ShowNodePool" { Require-NodePool; Invoke-AzGuarded @("aks", "nodepool", "show", "--resource-group", $ResourceGroup, "--cluster-name", $ClusterName, "--name", $NodePoolName, "-o", "table") }
  "ScaleNodePool" {
    Require-NodePool
    if ($PSBoundParameters.ContainsKey("NodeCount") -eq $false) { throw "-NodeCount is required for ScaleNodePool." }
    Invoke-AzGuarded (@("aks", "nodepool", "scale", "--resource-group", $ResourceGroup, "--cluster-name", $ClusterName, "--name", $NodePoolName, "--node-count", "$NodeCount") + $waitArgs) -NeedsApply
  }
  "StartNodePool" { Require-NodePool; Invoke-AzGuarded (@("aks", "nodepool", "start", "--resource-group", $ResourceGroup, "--cluster-name", $ClusterName, "--name", $NodePoolName) + $waitArgs) -NeedsApply }
  "StopNodePool" { Require-NodePool; Invoke-AzGuarded (@("aks", "nodepool", "stop", "--resource-group", $ResourceGroup, "--cluster-name", $ClusterName, "--name", $NodePoolName) + $waitArgs) -NeedsApply }
  "DeleteNodePool" { Require-NodePool; Invoke-AzGuarded (@("aks", "nodepool", "delete", "--resource-group", $ResourceGroup, "--cluster-name", $ClusterName, "--name", $NodePoolName) + $waitArgs) -NeedsApply }
}
