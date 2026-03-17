# Bootstrap Layer

`platform/bootstrap/` owns the shared demo foundation:

- VPC and EKS cluster for the portfolio environment
- core EKS managed addons (`vpc-cni`, `kube-proxy`, `coredns`)
- GitHub OIDC roles for bootstrap and service delivery workflows
- Cloudflare-managed public DNS for shared platform entrypoints
- shared Terraform state bucket and lock table
- ArgoCD, Backstage, and observability install assets

It does not own service-specific AWS resources. Those live behind `platform/modules/service-stack/`.

## Bootstrap Sequence

1. Apply `terraform/` to create the VPC, EKS cluster, core EKS addons, bootstrap operator cluster-admin access entry, state primitives, and GitHub OIDC roles.
2. Use the generated kubeconfig and Helm values to install:
   - ingress-nginx from `ingress-nginx/`
   - ArgoCD from `argocd/`
   - kube-prometheus-stack and OpenTelemetry Collector from `observability/`
   - Backstage from `backstage/`
3. Re-apply `terraform/` with the ingress load balancer hostname plus Cloudflare zone id to create public DNS records.
4. Point Backstage at `platform/templates/service-api/template.yaml`.

## Validation

```bash
terraform -chdir=platform/bootstrap/terraform init -backend=false
terraform -chdir=platform/bootstrap/terraform validate
terraform -chdir=platform/bootstrap/terraform fmt -check
```

## Cloudflare Auth

The Cloudflare provider reads authentication from the environment, not from a Terraform input variable. Export `CLOUDFLARE_API_TOKEN` before running `terraform apply`, then pass only `cloudflare_zone_id` and `ingress_public_hostname` as Terraform variables.
