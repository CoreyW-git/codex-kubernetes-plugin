param(
  [Parameter(Mandatory = $true)]
  [ValidateSet(
    "CurrentContext",
    "GetNodes",
    "GetNamespaces",
    "GetPods",
    "GetDeployments",
    "GetServices",
    "GetIngress",
    "GetEvents",
    "DescribeNode",
    "DescribePod",
    "Logs",
    "TopNodes",
    "TopPods",
    "ScaleDeployment",
    "RolloutStatus",
    "RolloutHistory",
    "RolloutRestart",
    "RolloutUndo",
    "RolloutPause",
    "RolloutResume",
    "CordonNode",
    "UncordonNode",
    "DrainNode",
    "DeletePod"
  )]
  [string]$Action,

  [string]$Namespace = "default",
  [string]$Name,
  [string]$Container,
  [int]$Replicas,
  [switch]$AllNamespaces,
  [switch]$Previous,
  [switch]$Apply,
  [switch]$Force
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
  throw "kubectl was not found on PATH."
}

function Invoke-Guarded {
  param(
    [string[]]$ArgsList,
    [switch]$NeedsApply
  )

  Write-Host "kubectl $($ArgsList -join ' ')"
  if ($NeedsApply -and -not $Apply) {
    Write-Host "No changes made. Re-run with -Apply to execute this administrative action."
    return
  }

  & kubectl @ArgsList
}

function Require-Name {
  if (-not $Name) {
    throw "-Name is required for action $Action."
  }
}

$nsArgs = @()
if ($AllNamespaces) {
  $nsArgs = @("--all-namespaces")
} elseif ($Namespace) {
  $nsArgs = @("--namespace", $Namespace)
}

switch ($Action) {
  "CurrentContext" { Invoke-Guarded @("config", "current-context") }
  "GetNodes" { Invoke-Guarded @("get", "nodes", "-o", "wide") }
  "GetNamespaces" { Invoke-Guarded @("get", "namespaces") }
  "GetPods" { Invoke-Guarded (@("get", "pods") + $nsArgs + @("-o", "wide")) }
  "GetDeployments" { Invoke-Guarded (@("get", "deployments") + $nsArgs) }
  "GetServices" { Invoke-Guarded (@("get", "services") + $nsArgs) }
  "GetIngress" { Invoke-Guarded (@("get", "ingress") + $nsArgs) }
  "GetEvents" { Invoke-Guarded (@("get", "events") + $nsArgs + @("--sort-by=.lastTimestamp")) }
  "DescribeNode" { Require-Name; Invoke-Guarded @("describe", "node", $Name) }
  "DescribePod" { Require-Name; Invoke-Guarded (@("describe", "pod", $Name) + $nsArgs) }
  "Logs" {
    Require-Name
    $argsList = @("logs", $Name) + $nsArgs
    if ($Container) { $argsList += @("-c", $Container) }
    if ($Previous) { $argsList += "--previous" }
    Invoke-Guarded $argsList
  }
  "TopNodes" { Invoke-Guarded @("top", "nodes") }
  "TopPods" { Invoke-Guarded (@("top", "pods") + $nsArgs) }
  "ScaleDeployment" {
    Require-Name
    if ($PSBoundParameters.ContainsKey("Replicas") -eq $false) {
      throw "-Replicas is required for ScaleDeployment."
    }
    Invoke-Guarded (@("scale", "deployment", $Name, "--replicas", "$Replicas") + $nsArgs) -NeedsApply
  }
  "RolloutStatus" { Require-Name; Invoke-Guarded (@("rollout", "status", "deployment/$Name") + $nsArgs) }
  "RolloutHistory" { Require-Name; Invoke-Guarded (@("rollout", "history", "deployment/$Name") + $nsArgs) }
  "RolloutRestart" { Require-Name; Invoke-Guarded (@("rollout", "restart", "deployment/$Name") + $nsArgs) -NeedsApply }
  "RolloutUndo" { Require-Name; Invoke-Guarded (@("rollout", "undo", "deployment/$Name") + $nsArgs) -NeedsApply }
  "RolloutPause" { Require-Name; Invoke-Guarded (@("rollout", "pause", "deployment/$Name") + $nsArgs) -NeedsApply }
  "RolloutResume" { Require-Name; Invoke-Guarded (@("rollout", "resume", "deployment/$Name") + $nsArgs) -NeedsApply }
  "CordonNode" { Require-Name; Invoke-Guarded @("cordon", $Name) -NeedsApply }
  "UncordonNode" { Require-Name; Invoke-Guarded @("uncordon", $Name) -NeedsApply }
  "DrainNode" {
    Require-Name
    $argsList = @("drain", $Name, "--ignore-daemonsets", "--delete-emptydir-data")
    if ($Force) { $argsList += "--force" }
    Invoke-Guarded $argsList -NeedsApply
  }
  "DeletePod" { Require-Name; Invoke-Guarded (@("delete", "pod", $Name) + $nsArgs) -NeedsApply }
}
