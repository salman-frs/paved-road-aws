# Bootstrap Layer

`platform/bootstrap/` owns the shared portfolio foundation and the operator-facing bootstrap flow.

State ownership is split on purpose:

- `admin/terraform/` is the persistent control plane
- `cluster/terraform/` is the disposable demo environment
- `argocd/` contains the minimal Argo bootstrap plus the root app-of-apps
- `ingress-nginx/`, `backstage/`, and `observability/` contain Helm values consumed by Argo

It does not own service-specific AWS resources. Those live behind `platform/modules/service-stack/`.

## What Each State Owns

`platform/bootstrap/admin/terraform` owns:

- shared Terraform state bucket and lock table
- GitHub OIDC provider
- GitHub Actions day-2 service delivery role

`platform/bootstrap/cluster/terraform` owns:

- VPC and EKS cluster for the portfolio environment
- core EKS managed addons (`vpc-cni`, `kube-proxy`, `coredns`)
- bootstrap operator cluster-admin access entry
- Cloudflare-managed DNS records for shared platform entrypoints

The cluster state intentionally uses the AWS-owned default key path for EKS secret encryption, so it does not create a customer-managed KMS key.

## Recommended Bootstrap Sequence

Bootstrap is a local operator workflow, not a GitHub Actions workflow.

1. Initialize and apply `platform/bootstrap/admin/terraform`.
2. Initialize and apply `platform/bootstrap/cluster/terraform` against the backend primitives created by the admin state.
3. Generate kubeconfig for the new cluster.
4. Install minimal ArgoCD locally with Helm from `platform/bootstrap/argocd/`.
5. Apply `platform/bootstrap/argocd/project.yaml` and `platform/bootstrap/argocd/root-application.yaml`.
6. Let Argo reconcile:
   - `ingress-nginx`
   - `kube-prometheus-stack`
   - `otel-collector`
   - `backstage`
7. Re-apply `platform/bootstrap/cluster/terraform` with the ingress load balancer hostname and Cloudflare zone id to publish public DNS.

The supported command surface for this sequence is the repo [justfile](/Users/salman/codex/paved-road-aws/justfile):

```bash
just bootstrap-admin-init
just bootstrap-admin-apply
just bootstrap-cluster-init
just bootstrap-cluster-apply
just bootstrap-kubeconfig
just bootstrap-argocd
just bootstrap-dns
```

## Safe Teardown

Do not run raw `terraform destroy` against a live cluster that still has platform applications installed. `ingress-nginx` creates an AWS load balancer outside Terraform, and its ELB, ENIs, and security group can outlive the Kubernetes objects long enough to block subnet and VPC deletion.

Supported destroy order:

1. Remove the Argo root application so child applications are pruned.
2. Uninstall the minimal ArgoCD bootstrap release.
3. Wait for Kubernetes-created AWS load balancer artifacts to disappear from the bootstrap VPC.
4. Destroy `platform/bootstrap/cluster/terraform`.
5. Only if you intentionally want to remove the persistent control plane, destroy `platform/bootstrap/admin/terraform`.

Use the repo `justfile` for the supported paths:

```bash
just destroy
just nuke
```

- `just destroy` removes platform applications and the disposable cluster state.
- `just nuke` also removes the persistent admin control plane.

## Validation

```bash
terraform -chdir=platform/bootstrap/admin/terraform init -backend=false
terraform -chdir=platform/bootstrap/admin/terraform fmt -check
terraform -chdir=platform/bootstrap/admin/terraform validate

terraform -chdir=platform/bootstrap/cluster/terraform init -backend=false
terraform -chdir=platform/bootstrap/cluster/terraform fmt -check
terraform -chdir=platform/bootstrap/cluster/terraform validate
```

## Cloudflare Auth

The Cloudflare provider reads authentication from the environment, not from a Terraform input variable. Export `CLOUDFLARE_API_TOKEN` before running `terraform apply`, then pass `cloudflare_zone_id` and `ingress_public_hostname` as Terraform variables only when DNS should be published.
