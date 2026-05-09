# Kubernetes Manager

Kubernetes Manager is a Codex plugin for bringing new projects into Kubernetes and using Docker Desktop Kubernetes for local development.

## What It Adds

- A Codex skill for Kubernetes project onboarding, manifest generation, validation, and cluster operations.
- PowerShell helper scripts for Windows and Docker Desktop workflows.
- A repo-local marketplace entry so the plugin can be carried through GitHub and made available to other projects.

## Suggested Repository Layout

```text
plugins/kubernetes-manager/
  .codex-plugin/plugin.json
  skills/kubernetes-management/SKILL.md
  scripts/
    check-docker-desktop-kubernetes.ps1
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

References:

- Docker Desktop Kubernetes: https://docs.docker.com/desktop/use-desktop/kubernetes/
- Kubernetes API v1.24: https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.24/
