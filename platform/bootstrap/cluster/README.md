# Bootstrap Cluster State

`platform/bootstrap/cluster/terraform/` is the disposable infrastructure state for the demo environment.

It owns:

- the shared VPC
- the EKS cluster
- the core managed addons required before workloads are healthy
- the bootstrap operator access entry
- the Cloudflare DNS anchor and shared public hostnames

It does not own:

- Terraform backend primitives
- GitHub OIDC provider and CI roles
- in-cluster platform applications after Argo is bootstrapped

## Lifecycle

Initialize this state only after the admin state has created the backend bucket and lock table.

```bash
just bootstrap-cluster-init
just bootstrap-cluster-apply
just bootstrap-kubeconfig
just bootstrap-dns
```

`bootstrap-dns` is intentionally a second apply. It should run only after `ingress-nginx` has created a load balancer hostname that can be exposed through Cloudflare.

## Validation

```bash
terraform -chdir=platform/bootstrap/cluster/terraform init -backend=false
terraform -chdir=platform/bootstrap/cluster/terraform fmt -check
terraform -chdir=platform/bootstrap/cluster/terraform validate
```
