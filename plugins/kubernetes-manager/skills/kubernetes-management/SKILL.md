---
name: kubernetes-management
description: Use when a project needs Kubernetes integration, manifest generation, Docker Desktop Kubernetes local development support, kubectl validation, deployment troubleshooting, or Kubernetes resource operations.
---

# Kubernetes Management

Use this skill when the user asks to integrate an app or service with Kubernetes, prepare manifests, operate a local Docker Desktop Kubernetes cluster, validate Kubernetes resources, or apply workloads with `kubectl`.

## Operating Principles

- Inspect the project first: language/runtime, build tool, existing Dockerfile or Compose files, ports, health endpoints, environment variables, secrets, persistence needs, and CI/CD conventions.
- Prefer Kubernetes-native resources with stable APIs: `apps/v1` Deployment, `v1` Service, `v1` ConfigMap/Secret references, `networking.k8s.io/v1` Ingress, `batch/v1` Job/CronJob when appropriate.
- Use controllers rather than direct Pods for application workloads.
- Keep generated manifests in `k8s/` unless the project already has a Kubernetes directory convention.
- Never hard-code secret values into manifests. Use `Secret` placeholders, external secret tooling, or documented manual steps.
- Validate before applying: `kubectl apply --dry-run=client -f <path>` and, when connected to a cluster, `kubectl diff -f <path>` or server-side dry runs when appropriate.
- Keep local Docker Desktop assumptions separate from production cluster assumptions.

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
- `scripts/scaffold-kubernetes-project.ps1`: creates starter `k8s/` manifests for a service.
- `scripts/kubernetes-apply.ps1`: validates, diffs, and applies a manifest directory.

## API Reference Notes

Kubernetes resource objects generally include `metadata`, `spec`, and `status`. Users normally define desired state in `spec`; the API server manages `status`.

Common operations are create, replace/update, patch, get, list, watch, and delete. Prefer `kubectl` for normal project workflows, and use direct API calls only when a task requires API-level behavior.

## Completion Criteria

Before finishing a Kubernetes integration task, report:

- Files created or changed.
- The target namespace, image name, ports, and service type.
- Validation performed and whether it passed.
- The exact command to apply locally.
- Any assumptions that must be adjusted for production.
