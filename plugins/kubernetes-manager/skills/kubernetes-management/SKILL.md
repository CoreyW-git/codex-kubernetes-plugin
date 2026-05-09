---
name: kubernetes-management
description: Use when a project needs Kubernetes integration, manifest generation, Docker Desktop Kubernetes local development support, OKE or Azure AKS cloud deployment support, kubectl validation, deployment troubleshooting, workload operations, cluster administration, or Kubernetes resource operations.
---

# Kubernetes Management

Use this skill when the user asks to integrate an app or service with Kubernetes, prepare manifests, operate a local Docker Desktop Kubernetes cluster, connect to managed cloud Kubernetes, validate Kubernetes resources, apply workloads with `kubectl`, or use the Kubernetes Manager callable tools.

## Operating Principles

- Inspect the project first: language/runtime, build tool, existing Dockerfile or Compose files, ports, health endpoints, environment variables, secrets, persistence needs, and CI/CD conventions.
- Prefer Kubernetes-native resources with stable APIs: `apps/v1` Deployment, `v1` Service, `v1` ConfigMap/Secret references, `networking.k8s.io/v1` Ingress, `batch/v1` Job/CronJob when appropriate.
- Use controllers rather than direct Pods for application workloads.
- Keep generated manifests in `k8s/` unless the project already has a Kubernetes directory convention.
- Never hard-code secret values into manifests. Use `Secret` placeholders, external secret tooling, or documented manual steps.
- Validate before applying: `kubectl apply --dry-run=client -f <path>` and, when connected to a cluster, `kubectl diff -f <path>` or server-side dry runs when appropriate.
- Keep local Docker Desktop assumptions separate from production cluster assumptions.
- For cloud deployments, confirm the target provider, subscription/tenancy, region, cluster, namespace, image registry, and current `kubectl` context before applying.
- Treat "AKE" as Azure Kubernetes Service unless the user clarifies a different provider. Azure's CLI surface is `az aks`.
- For cluster administration, prefer read-only inventory and diagnostics first. Require explicit user intent before destructive or cost-impacting actions such as deleting clusters, deleting node pools, scaling to zero, draining nodes, or stopping clusters.
- When the plugin's MCP server is available, prefer the directly callable Kubernetes Manager tools over ad hoc shell commands for supported operations.

## Docker Desktop Kubernetes Workflow

Docker Desktop Kubernetes should be treated as the local development cluster.

1. Confirm tooling: Docker Desktop running, `kubectl` installed, and Kubernetes enabled.
2. Check the local context:

```powershell
kubectl config current-context
kubectl config use-context docker-desktop
kubectl get nodes
```

3. If Kubernetes is not enabled or no nodes are Ready, guide the user to Docker Desktop settings and the Kubernetes dashboard.
4. Prefer the `kind` provisioner when the user wants multi-node local development or a selectable Kubernetes version. `kubeadm` is the older single-node option.
5. If cluster behavior looks stale after Docker Desktop upgrades, suggest a reset only after preserving anything important in the local cluster.

## Cloud Kubernetes Workflow

Cloud deployments target existing managed Kubernetes clusters. Do not create or delete cloud resources unless the user explicitly asks for that lifecycle work.

### OKE

Oracle Container Engine for Kubernetes uses OCI CLI to write kubeconfig credentials:

```powershell
oci ce cluster create-kubeconfig --cluster-id <cluster-ocid> --file "$HOME\.kube\config" --region <region> --token-version 2.0.0 --kube-endpoint PUBLIC_ENDPOINT
kubectl config current-context
kubectl get nodes
```

Use `PRIVATE_ENDPOINT` instead of `PUBLIC_ENDPOINT` only when the developer is on a network path that can reach the private endpoint.

### AKE / Azure AKS

When the user says AKE, assume Azure Kubernetes Service unless they clarify another provider. Azure uses `az aks` commands:

```powershell
az aks get-credentials --resource-group <resource-group> --name <cluster-name> --overwrite-existing
kubectl config current-context
kubectl get nodes
```

Use admin credentials only when the user explicitly asks for administrative cluster credentials.

### Cloud Deploy Safety

Before applying to OKE or AKS:

1. Confirm the current `kubectl` context is the intended cloud cluster and not `docker-desktop`.
2. Confirm manifests reference a cloud-accessible image registry, not a purely local image tag.
3. Use a namespace appropriate to the environment.
4. Run a dry run and diff first.
5. Apply only after the target context and namespace are clear.

## Cluster Administration Workflow

Use this workflow when the user asks to operate or administer Kubernetes beyond applying manifests.

1. Identify the target:
   - Local `docker-desktop`
   - OKE
   - Azure AKS
   - Another kubeconfig context
2. Run read-only discovery first:
   - `kubectl config current-context`
   - `kubectl get nodes -o wide`
   - `kubectl get namespaces`
   - `kubectl get pods --all-namespaces`
   - `kubectl get events --all-namespaces --sort-by=.lastTimestamp`
3. For workload operations, use `kubectl`:
   - Scale deployments or statefulsets.
   - Restart rollouts.
   - Pause/resume rollouts.
   - Check rollout status and history.
   - Inspect pod logs, descriptions, events, and resource usage.
4. For node operations, treat cordon/drain as disruptive. Confirm the node name and context before using them.
5. For provider-managed node pools and cluster lifecycle:
   - Use `az aks` and `az aks nodepool` for AKS.
   - Use `oci ce cluster`, `oci ce node-pool`, and `oci ce work-request` for OKE.
6. After any mutation, verify the result with read-only commands.

## Supported Administration Capabilities

Common Kubernetes:

- Inventory: contexts, nodes, namespaces, pods, deployments, services, ingress, events.
- Diagnostics: describe nodes/pods/deployments, get logs, show rollout status/history, inspect resource usage when metrics server is available.
- Workload operations: scale deployments, restart deployments, pause/resume rollouts, undo rollouts, delete pods for controller-managed restart behavior.
- Node operations: cordon, uncordon, and drain with explicit confirmation.

Azure AKS:

- List/show clusters.
- Start/stop clusters.
- Get credentials.
- List/show node pools.
- Scale/start/stop/delete node pools with explicit `-Apply`.

OKE:

- List/show clusters.
- List addons and work requests.
- List/show node pools.
- Delete clusters, node pools, or individual nodes only with explicit `-Apply`.

## Callable Tool Workflow

This plugin exposes a local MCP server through `.mcp.json`. When loaded, use these tools for supported operations:

- `kubernetes_current_context`: read the active kubeconfig context.
- `kubernetes_check_docker_desktop`: check local Docker Desktop Kubernetes.
- `kubernetes_cloud_prereqs`: check OKE or AKS/AKE CLI prerequisites.
- `kubernetes_connect_oke`: write kubeconfig for OKE.
- `kubernetes_connect_aks`: write kubeconfig for Azure AKS/AKE.
- `kubernetes_apply`: dry-run, diff, or apply local manifests.
- `kubernetes_cloud_apply`: guarded cloud deployment that rejects `docker-desktop`.
- `kubernetes_cluster_report`: generate a cluster inventory and health report.
- `kubernetes_admin`: common `kubectl` administration.
- `aks_admin`: AKS cluster and node pool administration.
- `oke_admin`: OKE cluster, node pool, addon, and work request administration.

Mutating tools require `apply: true`; otherwise they report the command that would be executed.

## Project Integration Checklist

When integrating a project, produce or update:

- `Dockerfile` if one is missing and containerization is needed.
- `k8s/namespace.yaml` when the project should be isolated.
- `k8s/deployment.yaml` for the app workload.
- `k8s/service.yaml` for stable in-cluster routing.
- `k8s/ingress.yaml` only if the project needs HTTP routing and an ingress controller exists.
- `k8s/configmap.yaml` for non-secret configuration.
- `k8s/secret.example.yaml` for secret names and keys only, with placeholder values.
- `k8s/kustomization.yaml` when multiple manifests are generated.
- `README.md` or project docs with build, load, validate, and deploy commands.

## Helper Scripts

Use scripts from this plugin directory when they fit the task:

- `scripts/check-docker-desktop-kubernetes.ps1`: verifies Docker, kubectl, current context, and node readiness.
- `scripts/check-cloud-kubernetes-prereqs.ps1`: verifies provider CLI and kubectl prerequisites for OKE or Azure AKS.
- `scripts/connect-oke-kubeconfig.ps1`: adds an OKE cluster to kubeconfig using OCI CLI.
- `scripts/connect-aks-kubeconfig.ps1`: adds an Azure AKS cluster to kubeconfig using Azure CLI. Use this for AKE requests unless clarified.
- `scripts/cloud-kubernetes-apply.ps1`: validates, diffs, and applies manifests to a non-local Kubernetes context.
- `scripts/kubernetes-cluster-report.ps1`: creates a read-only cluster health and inventory report.
- `scripts/kubernetes-admin.ps1`: runs common Kubernetes administration actions through `kubectl`.
- `scripts/aks-admin.ps1`: runs AKS cluster and node pool administration through Azure CLI.
- `scripts/oke-admin.ps1`: runs OKE cluster, node pool, addon, and work request administration through OCI CLI.
- `scripts/scaffold-kubernetes-project.ps1`: creates starter `k8s/` manifests for a service.
- `scripts/kubernetes-apply.ps1`: validates, diffs, and applies a manifest directory.

## API Reference Notes

Kubernetes resource objects generally include `metadata`, `spec`, and `status`. Users normally define desired state in `spec`; the API server manages `status`.

Common operations are create, replace/update, patch, get, list, watch, and delete. Prefer `kubectl` for normal project workflows, and use direct API calls only when a task requires API-level behavior.

## Completion Criteria

Before finishing a Kubernetes integration task, report:

- Files created or changed.
- The target namespace, image name, ports, and service type.
- For cloud deployments, the provider, cluster/context, region or resource group, and registry assumptions.
- Validation performed and whether it passed.
- The exact command to apply locally.
- Any assumptions that must be adjusted for production.
