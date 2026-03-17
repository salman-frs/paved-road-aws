# ingress-nginx Bootstrap Assets

This install creates the shared public ingress entrypoint for the demo cluster. After the `ingress-nginx-controller` service receives a load balancer hostname, bootstrap Terraform creates:

- `ingress.dev.salmanfrs.dev` as a DNS-only Cloudflare CNAME to the AWS load balancer
- proxied Cloudflare CNAMEs for ArgoCD, Backstage, and Grafana that point to that anchor

## Install

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  -f platform/bootstrap/ingress-nginx/values.yaml
```
