#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const childProcess = require("child_process");

const scriptsDir = __dirname;

const tools = [
  {
    name: "kubernetes_current_context",
    description: "Return the active kubectl context.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "kubernetes_check_docker_desktop",
    description: "Check Docker Desktop Kubernetes readiness and optionally switch kubectl to docker-desktop.",
    inputSchema: {
      type: "object",
      properties: {
        switchContext: { type: "boolean", description: "Switch kubectl to docker-desktop before checking nodes." }
      },
      additionalProperties: false
    }
  },
  {
    name: "kubernetes_cloud_prereqs",
    description: "Check cloud Kubernetes prerequisites for OKE or Azure AKS/AKE.",
    inputSchema: {
      type: "object",
      required: ["provider"],
      properties: {
        provider: { type: "string", enum: ["OKE", "AKS", "AKE"] }
      },
      additionalProperties: false
    }
  },
  {
    name: "kubernetes_connect_oke",
    description: "Connect kubectl to an OKE cluster using OCI CLI.",
    inputSchema: {
      type: "object",
      required: ["clusterId", "region"],
      properties: {
        clusterId: { type: "string" },
        region: { type: "string" },
        kubeEndpoint: { type: "string", enum: ["PUBLIC_ENDPOINT", "PRIVATE_ENDPOINT", "VCN_HOSTNAME", "LEGACY_KUBERNETES"] },
        kubeconfigPath: { type: "string" },
        profile: { type: "string" },
        overwrite: { type: "boolean" }
      },
      additionalProperties: false
    }
  },
  {
    name: "kubernetes_connect_aks",
    description: "Connect kubectl to an Azure AKS cluster using Azure CLI. Use for AKE requests unless clarified.",
    inputSchema: {
      type: "object",
      required: ["resourceGroup", "clusterName"],
      properties: {
        resourceGroup: { type: "string" },
        clusterName: { type: "string" },
        contextName: { type: "string" },
        kubeconfigPath: { type: "string" },
        admin: { type: "boolean" },
        overwriteExisting: { type: "boolean" }
      },
      additionalProperties: false
    }
  },
  {
    name: "kubernetes_apply",
    description: "Validate, diff, and optionally apply Kubernetes manifests.",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string", default: "k8s" },
        useKustomize: { type: "boolean" },
        apply: { type: "boolean" },
        skipDiff: { type: "boolean" }
      },
      additionalProperties: false
    }
  },
  {
    name: "kubernetes_cloud_apply",
    description: "Guarded cloud apply that refuses docker-desktop and can enforce an expected context.",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string", default: "k8s" },
        useKustomize: { type: "boolean" },
        expectedContext: { type: "string" },
        namespace: { type: "string" },
        apply: { type: "boolean" },
        skipDiff: { type: "boolean" }
      },
      additionalProperties: false
    }
  },
  {
    name: "kubernetes_cluster_report",
    description: "Create a read-only Kubernetes cluster inventory and health report.",
    inputSchema: {
      type: "object",
      properties: {
        namespace: { type: "string" },
        includeLogs: { type: "boolean" }
      },
      additionalProperties: false
    }
  },
  {
    name: "kubernetes_admin",
    description: "Run common kubectl administration actions. Mutating actions require apply=true.",
    inputSchema: {
      type: "object",
      required: ["action"],
      properties: {
        action: {
          type: "string",
          enum: [
            "CurrentContext", "GetNodes", "GetNamespaces", "GetPods", "GetDeployments", "GetServices", "GetIngress",
            "GetEvents", "DescribeNode", "DescribePod", "Logs", "TopNodes", "TopPods", "ScaleDeployment",
            "RolloutStatus", "RolloutHistory", "RolloutRestart", "RolloutUndo", "RolloutPause", "RolloutResume",
            "CordonNode", "UncordonNode", "DrainNode", "DeletePod"
          ]
        },
        namespace: { type: "string" },
        name: { type: "string" },
        container: { type: "string" },
        replicas: { type: "integer" },
        allNamespaces: { type: "boolean" },
        previous: { type: "boolean" },
        apply: { type: "boolean" },
        force: { type: "boolean" }
      },
      additionalProperties: false
    }
  },
  {
    name: "aks_admin",
    description: "Administer Azure AKS clusters and node pools. Mutating actions require apply=true.",
    inputSchema: {
      type: "object",
      required: ["action"],
      properties: {
        action: {
          type: "string",
          enum: [
            "ListClusters", "ShowCluster", "StartCluster", "StopCluster", "ScaleCluster",
            "ListNodePools", "ShowNodePool", "ScaleNodePool", "StartNodePool", "StopNodePool", "DeleteNodePool"
          ]
        },
        resourceGroup: { type: "string" },
        clusterName: { type: "string" },
        nodePoolName: { type: "string" },
        nodeCount: { type: "integer" },
        noWait: { type: "boolean" },
        apply: { type: "boolean" }
      },
      additionalProperties: false
    }
  },
  {
    name: "oke_admin",
    description: "Administer OKE clusters, node pools, nodes, addons, and work requests. Mutating actions require apply=true.",
    inputSchema: {
      type: "object",
      required: ["action"],
      properties: {
        action: {
          type: "string",
          enum: [
            "ListClusters", "ShowCluster", "DeleteCluster", "ListAddons", "ListNodePools", "ShowNodePool",
            "DeleteNodePool", "DeleteNode", "ListWorkRequests", "ShowWorkRequest"
          ]
        },
        compartmentId: { type: "string" },
        clusterId: { type: "string" },
        nodePoolId: { type: "string" },
        nodeId: { type: "string" },
        workRequestId: { type: "string" },
        region: { type: "string" },
        profile: { type: "string" },
        apply: { type: "boolean" }
      },
      additionalProperties: false
    }
  }
];

let buffer = Buffer.alloc(0);

process.stdin.on("data", function(chunk) {
  buffer = Buffer.concat([buffer, chunk]);
  readMessages();
});

function readMessages() {
  while (true) {
    const headerEnd = buffer.indexOf("\r\n\r\n");
    if (headerEnd === -1) return;

    const header = buffer.slice(0, headerEnd).toString("utf8");
    const match = /Content-Length:\s*(\d+)/i.exec(header);
    if (!match) {
      buffer = buffer.slice(headerEnd + 4);
      continue;
    }

    const length = Number(match[1]);
    const messageStart = headerEnd + 4;
    const messageEnd = messageStart + length;
    if (buffer.length < messageEnd) return;

    const payload = buffer.slice(messageStart, messageEnd).toString("utf8");
    buffer = buffer.slice(messageEnd);

    let message;
    try {
      message = JSON.parse(payload);
    } catch (error) {
      continue;
    }

    handleMessage(message);
  }
}

function send(message) {
  const json = JSON.stringify(message);
  const out = "Content-Length: " + Buffer.byteLength(json, "utf8") + "\r\n\r\n" + json;
  process.stdout.write(out);
}

function result(id, value) {
  send({ jsonrpc: "2.0", id: id, result: value });
}

function errorResult(id, code, message) {
  send({ jsonrpc: "2.0", id: id, error: { code: code, message: message } });
}

function handleMessage(message) {
  if (!message || !message.method) return;

  if (message.method === "initialize") {
    result(message.id, {
      protocolVersion: "2024-11-05",
      capabilities: { tools: {} },
      serverInfo: { name: "kubernetes-manager", version: "0.4.0" }
    });
    return;
  }

  if (message.method === "tools/list") {
    result(message.id, { tools: tools });
    return;
  }

  if (message.method === "tools/call") {
    callTool(message);
    return;
  }

  if (message.id !== undefined) {
    result(message.id, {});
  }
}

function callTool(message) {
  const params = message.params || {};
  const name = params.name;
  const args = params.arguments || {};

  try {
    const output = dispatch(name, args);
    result(message.id, {
      content: [{ type: "text", text: output }],
      isError: false
    });
  } catch (err) {
    result(message.id, {
      content: [{ type: "text", text: String(err && err.message ? err.message : err) }],
      isError: true
    });
  }
}

function dispatch(name, args) {
  switch (name) {
    case "kubernetes_current_context":
      return runCommand("kubectl", ["config", "current-context"]);
    case "kubernetes_check_docker_desktop":
      return runPowerShell("check-docker-desktop-kubernetes.ps1", boolArgs(args, { switchContext: "SwitchContext" }));
    case "kubernetes_cloud_prereqs":
      return runPowerShell("check-cloud-kubernetes-prereqs.ps1", valueArgs(args, { provider: "Provider" }));
    case "kubernetes_connect_oke":
      return runPowerShell("connect-oke-kubeconfig.ps1", mixedArgs(args, {
        clusterId: "ClusterId",
        region: "Region",
        kubeEndpoint: "KubeEndpoint",
        kubeconfigPath: "KubeconfigPath",
        profile: "Profile"
      }, { overwrite: "Overwrite" }));
    case "kubernetes_connect_aks":
      return runPowerShell("connect-aks-kubeconfig.ps1", mixedArgs(args, {
        resourceGroup: "ResourceGroup",
        clusterName: "ClusterName",
        contextName: "ContextName",
        kubeconfigPath: "KubeconfigPath"
      }, { admin: "Admin", overwriteExisting: "OverwriteExisting" }));
    case "kubernetes_apply":
      return runPowerShell("kubernetes-apply.ps1", mixedArgs(args, { path: "Path" }, {
        useKustomize: "UseKustomize",
        apply: "Apply",
        skipDiff: "SkipDiff"
      }));
    case "kubernetes_cloud_apply":
      return runPowerShell("cloud-kubernetes-apply.ps1", mixedArgs(args, {
        path: "Path",
        expectedContext: "ExpectedContext",
        namespace: "Namespace"
      }, { useKustomize: "UseKustomize", apply: "Apply", skipDiff: "SkipDiff" }));
    case "kubernetes_cluster_report":
      return runPowerShell("kubernetes-cluster-report.ps1", mixedArgs(args, { namespace: "Namespace" }, { includeLogs: "IncludeLogs" }));
    case "kubernetes_admin":
      return runPowerShell("kubernetes-admin.ps1", mixedArgs(args, {
        action: "Action",
        namespace: "Namespace",
        name: "Name",
        container: "Container",
        replicas: "Replicas"
      }, { allNamespaces: "AllNamespaces", previous: "Previous", apply: "Apply", force: "Force" }));
    case "aks_admin":
      return runPowerShell("aks-admin.ps1", mixedArgs(args, {
        action: "Action",
        resourceGroup: "ResourceGroup",
        clusterName: "ClusterName",
        nodePoolName: "NodePoolName",
        nodeCount: "NodeCount"
      }, { noWait: "NoWait", apply: "Apply" }));
    case "oke_admin":
      return runPowerShell("oke-admin.ps1", mixedArgs(args, {
        action: "Action",
        compartmentId: "CompartmentId",
        clusterId: "ClusterId",
        nodePoolId: "NodePoolId",
        nodeId: "NodeId",
        workRequestId: "WorkRequestId",
        region: "Region",
        profile: "Profile"
      }, { apply: "Apply" }));
    default:
      throw new Error("Unknown tool: " + name);
  }
}

function runPowerShell(scriptName, args) {
  const scriptPath = path.join(scriptsDir, scriptName);
  if (!fs.existsSync(scriptPath)) {
    throw new Error("Script not found: " + scriptPath);
  }

  return runCommand("powershell", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", scriptPath].concat(args || []));
}

function runCommand(command, args) {
  const child = childProcess.spawnSync(command, args || [], {
    cwd: process.cwd(),
    encoding: "utf8",
    windowsHide: true
  });

  const stdout = child.stdout || "";
  const stderr = child.stderr || "";
  const text = (stdout + (stderr ? "\n" + stderr : "")).trim();

  if (child.error) {
    throw child.error;
  }

  if (child.status !== 0) {
    throw new Error(text || command + " exited with status " + child.status);
  }

  return text || command + " completed successfully.";
}

function valueArgs(args, mapping) {
  const out = [];
  Object.keys(mapping).forEach(function(key) {
    if (args[key] !== undefined && args[key] !== null && args[key] !== "") {
      out.push("-" + mapping[key], String(args[key]));
    }
  });
  return out;
}

function boolArgs(args, mapping) {
  const out = [];
  Object.keys(mapping).forEach(function(key) {
    if (args[key] === true) {
      out.push("-" + mapping[key]);
    }
  });
  return out;
}

function mixedArgs(args, values, bools) {
  return valueArgs(args, values).concat(boolArgs(args, bools));
}
