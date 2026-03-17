# ArgoCD Bootstrap Assets

These values and manifests install ArgoCD and scope it to the `gitops/` paths owned by this repo.

## Install

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  -f platform/bootstrap/argocd/values.yaml

kubectl apply -f platform/bootstrap/argocd/project.yaml
```

Public hostname: `argocd.salmanfrs.dev`
