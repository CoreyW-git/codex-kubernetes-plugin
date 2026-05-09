param(
  [string]$Namespace,
  [switch]$IncludeLogs
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
  throw "kubectl was not found on PATH."
}

function Section {
  param([string]$Title)
  Write-Host ""
  Write-Host "== $Title =="
}

$nsArgs = @()
if ($Namespace) {
  $nsArgs = @("--namespace", $Namespace)
}

Section "Context"
kubectl config current-context

Section "Cluster Info"
kubectl cluster-info

Section "Nodes"
kubectl get nodes -o wide

Section "Namespaces"
kubectl get namespaces

Section "Workloads"
if ($Namespace) {
  kubectl get deployments,statefulsets,daemonsets,jobs,cronjobs @nsArgs
} else {
  kubectl get deployments,statefulsets,daemonsets,jobs,cronjobs --all-namespaces
}

Section "Pods"
if ($Namespace) {
  kubectl get pods @nsArgs -o wide
} else {
  kubectl get pods --all-namespaces -o wide
}

Section "Services and Ingress"
if ($Namespace) {
  kubectl get services,ingress @nsArgs
} else {
  kubectl get services,ingress --all-namespaces
}

Section "Recent Events"
if ($Namespace) {
  kubectl get events @nsArgs --sort-by=.lastTimestamp
} else {
  kubectl get events --all-namespaces --sort-by=.lastTimestamp
}

Section "Resource Usage"
try {
  kubectl top nodes
  if ($Namespace) {
    kubectl top pods @nsArgs
  } else {
    kubectl top pods --all-namespaces
  }
} catch {
  Write-Warning "Metrics API is unavailable or metrics-server is not installed."
}

if ($IncludeLogs) {
  Section "Unhealthy Pod Logs"
  $json = if ($Namespace) {
    kubectl get pods @nsArgs -o json | ConvertFrom-Json
  } else {
    kubectl get pods --all-namespaces -o json | ConvertFrom-Json
  }

  foreach ($pod in $json.items) {
    $phase = $pod.status.phase
    $waiting = @($pod.status.containerStatuses | Where-Object { $_.state.waiting })
    if ($phase -ne "Running" -or $waiting.Count -gt 0) {
      Write-Host ""
      Write-Host "-- $($pod.metadata.namespace)/$($pod.metadata.name) --"
      kubectl logs $pod.metadata.name --namespace $pod.metadata.namespace --tail 100
    }
  }
}
