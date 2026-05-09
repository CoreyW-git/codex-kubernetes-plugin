param(
  [Parameter(Mandatory = $true)]
  [string]$Name,

  [string]$Namespace = "default",
  [string]$Image = "$Name:local",
  [int]$ContainerPort = 8080,
  [int]$ServicePort = 80,
  [ValidateSet("ClusterIP", "NodePort", "LoadBalancer")]
  [string]$ServiceType = "ClusterIP",
  [string]$OutputPath = "k8s"
)

$ErrorActionPreference = "Stop"

New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null

$labels = "app: $Name"

$deployment = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $Name
  namespace: $Namespace
  labels:
    $labels
spec:
  replicas: 1
  selector:
    matchLabels:
      $labels
  template:
    metadata:
      labels:
        $labels
    spec:
      containers:
        - name: $Name
          image: $Image
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: $ContainerPort
          readinessProbe:
            httpGet:
              path: /
              port: $ContainerPort
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /
              port: $ContainerPort
            initialDelaySeconds: 15
            periodSeconds: 20
"@

$service = @"
apiVersion: v1
kind: Service
metadata:
  name: $Name
  namespace: $Namespace
  labels:
    $labels
spec:
  type: $ServiceType
  selector:
    $labels
  ports:
    - name: http
      port: $ServicePort
      targetPort: $ContainerPort
"@

$kustomization = @"
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
"@

Set-Content -Path (Join-Path $OutputPath "deployment.yaml") -Value $deployment -Encoding utf8
Set-Content -Path (Join-Path $OutputPath "service.yaml") -Value $service -Encoding utf8
Set-Content -Path (Join-Path $OutputPath "kustomization.yaml") -Value $kustomization -Encoding utf8

Write-Host "Created Kubernetes manifests in $OutputPath"
Write-Host "Validate with: kubectl apply --dry-run=client -k $OutputPath"
