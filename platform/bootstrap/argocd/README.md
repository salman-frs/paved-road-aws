# ArgoCD Bootstrap Assets

These assets support a two-stage Argo model:

- a minimal local Helm install for the Argo control plane itself
- a declarative root application that lets Argo manage the rest of the platform stack from Git

## Bootstrap

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm upgrade --install argocd argo/argo-cd \
  --version 9.4.12 \
  --namespace argocd \
  --create-namespace \
  -f platform/bootstrap/argocd/values.yaml \
  --wait \
  --timeout 15m

kubectl apply -f platform/bootstrap/argocd/project.yaml
kubectl apply -f platform/bootstrap/argocd/root-application.yaml
```

The root application reconciles the child applications under `platform/bootstrap/argocd/apps/`, which in turn install `ingress-nginx`, observability, and Backstage from pinned upstream Helm charts plus repo-owned values files.

Public hostname: `argocd.salmanfrs.dev`
