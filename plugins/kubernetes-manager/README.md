# Kubernetes Manager

Kubernetes Manager is a Codex plugin for bringing new projects into Kubernetes, using Docker Desktop Kubernetes for local development, deploying to managed cloud Kubernetes, administering Kubernetes clusters, and exposing Kubernetes operations as callable Codex tools.

## What It Adds

- A Codex skill for Kubernetes project onboarding, manifest generation, validation, workload operations, and cluster administration.
- A local MCP server that exposes Kubernetes actions as directly callable tools in Codex sessions.
- PowerShell helper scripts for Windows, Docker Desktop, OKE, and Azure AKS workflows.
- A repo-local marketplace entry so the plugin can be carried through GitHub and made available to other projects.

## Suggested Repository Layout

```text
plugins/kubernetes-manager/
  .codex-plugin/plugin.json
  .mcp.json
  skills/kubernetes-management/SKILL.md
  scripts/
    kubernetes-mcp-server.js
    check-docker-desktop-kubernetes.ps1
    check-cloud-kubernetes-prereqs.ps1
    connect-aks-kubeconfig.ps1
    connect-oke-kubeconfig.ps1
    cloud-kubernetes-apply.ps1
    kubernetes-admin.ps1
    kubernetes-cluster-report.ps1
    aks-admin.ps1
    oke-admin.ps1
    install-into-project.ps1
    scaffold-kubernetes-project.ps1
    kubernetes-apply.ps1
```

## Installing Into Another Project

Copy this plugin folder into the target repository under `plugins/kubernetes-manager`, then add or merge the marketplace entry from `.agents/plugins/marketplace.json`.

From a checkout that contains this plugin, you can also run:

```powershell
.\plugins\kubernetes-manager\scripts\install-into-project.ps1 -TargetProjectPath C:\path\to\project
```

For GitHub reuse, commit both:

- `plugins/kubernetes-manager`
- `.agents/plugins/marketplace.json`

## Local Development Assumptions

The local cluster workflow targets Docker Desktop Kubernetes and expects `kubectl` on PATH. Docker Desktop should use the `docker-desktop` Kubernetes context for local operations.

## Cloud Deployment Assumptions

Cloud deployment workflows target existing managed Kubernetes clusters:

- OKE: Oracle Container Engine for Kubernetes, using OCI CLI and `oci ce cluster create-kubeconfig`.
- AKE/AKS: Treated as Azure Kubernetes Service, using Azure CLI and `az aks get-credentials`.

The plugin does not store cloud credentials. It expects the developer to authenticate with the provider CLI before connecting kubeconfig or deploying.

Example checks:

```powershell
.\plugins\kubernetes-manager\scripts\check-cloud-kubernetes-prereqs.ps1 -Provider OKE
.\plugins\kubernetes-manager\scripts\check-cloud-kubernetes-prereqs.ps1 -Provider AKE
```

Example kubeconfig setup:

```powershell
.\plugins\kubernetes-manager\scripts\connect-oke-kubeconfig.ps1 -ClusterId "ocid1.cluster..." -Region "us-ashburn-1"
.\plugins\kubernetes-manager\scripts\connect-aks-kubeconfig.ps1 -ResourceGroup "my-rg" -ClusterName "my-aks"
```

Example guarded cloud apply:

```powershell
.\plugins\kubernetes-manager\scripts\cloud-kubernetes-apply.ps1 -Path k8s -UseKustomize -ExpectedContext "my-cloud-context"
```

## Cluster Administration

Common Kubernetes administration:

```powershell
.\plugins\kubernetes-manager\scripts\kubernetes-cluster-report.ps1
.\plugins\kubernetes-manager\scripts\kubernetes-admin.ps1 -Action GetEvents -Namespace default
.\plugins\kubernetes-manager\scripts\kubernetes-admin.ps1 -Action ScaleDeployment -Namespace default -Name api -Replicas 3 -Apply
.\plugins\kubernetes-manager\scripts\kubernetes-admin.ps1 -Action RolloutRestart -Namespace default -Name api -Apply
```

AKS administration:

```powershell
.\plugins\kubernetes-manager\scripts\aks-admin.ps1 -Action ListClusters -ResourceGroup "my-rg"
.\plugins\kubernetes-manager\scripts\aks-admin.ps1 -Action ListNodePools -ResourceGroup "my-rg" -ClusterName "my-aks"
.\plugins\kubernetes-manager\scripts\aks-admin.ps1 -Action ScaleNodePool -ResourceGroup "my-rg" -ClusterName "my-aks" -NodePoolName "system" -NodeCount 3 -Apply
```

OKE administration:

```powershell
.\plugins\kubernetes-manager\scripts\oke-admin.ps1 -Action ListClusters -CompartmentId "ocid1.compartment..."
.\plugins\kubernetes-manager\scripts\oke-admin.ps1 -Action ListNodePools -CompartmentId "ocid1.compartment..." -ClusterId "ocid1.cluster..."
.\plugins\kubernetes-manager\scripts\oke-admin.ps1 -Action GetWorkRequests -CompartmentId "ocid1.compartment..."
```

Destructive or cost-impacting actions require `-Apply`; otherwise scripts print the command they would run.

## Callable Tools

When the plugin is installed and Codex loads its MCP server, sessions can call tools directly instead of only asking Codex to run scripts.

Exposed tools:

- `kubernetes_current_context`
- `kubernetes_check_docker_desktop`
- `kubernetes_cloud_prereqs`
- `kubernetes_connect_oke`
- `kubernetes_connect_aks`
- `kubernetes_apply`
- `kubernetes_cloud_apply`
- `kubernetes_cluster_report`
- `kubernetes_admin`
- `aks_admin`
- `oke_admin`

The tools use the same guarded scripts. Mutating actions still require explicit `apply: true`.

References:

- Docker Desktop Kubernetes: https://docs.docker.com/desktop/use-desktop/kubernetes/
- Kubernetes API v1.24: https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.24/
- OKE kubeconfig command: https://docs.oracle.com/iaas/tools/oci-cli/latest/oci_cli_docs/cmdref/ce/cluster/create-kubeconfig.html
- Azure AKS credentials command: https://learn.microsoft.com/cli/azure/aks
- AKS node pool commands: https://learn.microsoft.com/cli/azure/aks/nodepool
- OKE CLI commands: https://docs.oracle.com/iaas/tools/oci-cli/latest/oci_cli_docs/cmdref/ce.html
