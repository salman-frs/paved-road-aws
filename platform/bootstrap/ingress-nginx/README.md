# ingress-nginx Bootstrap Assets

This install creates the shared public ingress entrypoint for the demo cluster. It is installed by Argo after the minimal Argo control plane is bootstrapped locally. After the `ingress-nginx-controller` service receives a load balancer hostname, cluster bootstrap Terraform creates:

- `ingress.dev.salmanfrs.dev` as a DNS-only Cloudflare CNAME to the AWS load balancer
- proxied Cloudflare CNAMEs for ArgoCD, Backstage, and Grafana that point to that anchor

Because the controller service is `type: LoadBalancer`, AWS creates the load balancer outside Terraform. Teardown must uninstall the Helm release before destroying the bootstrap VPC, or orphaned ELB ENIs and security groups can block VPC deletion.

Argo deploys the ingress release from [platform/bootstrap/argocd/apps/ingress-nginx.yaml](/Users/salman/codex/paved-road-aws/platform/bootstrap/argocd/apps/ingress-nginx.yaml), using [platform/bootstrap/ingress-nginx/values.yaml](/Users/salman/codex/paved-road-aws/platform/bootstrap/ingress-nginx/values.yaml) as the repo-owned chart values.
