# Bootstrap Admin State

`platform/bootstrap/admin/terraform/` is the persistent bootstrap control plane.

It owns:

- the shared S3 bucket for Terraform state
- the DynamoDB table for Terraform locking
- the GitHub OIDC provider
- the GitHub Actions role used by day-2 service delivery

It deliberately does not own the EKS cluster or platform applications. Those belong to [platform/bootstrap/cluster/README.md](/Users/salman/codex/paved-road-aws/platform/bootstrap/cluster/README.md) and the Argo-managed platform stack.

## Lifecycle

Run this state locally first. It creates the shared S3 backend and lock table used by the cluster state and downstream Terraform consumers, but the admin state itself remains local by design.

```bash
just bootstrap-admin-init
just bootstrap-admin-apply
```

Normal cluster teardown should not destroy this state. Only use `just nuke` when you explicitly want to remove the control plane itself.

## Validation

```bash
terraform -chdir=platform/bootstrap/admin/terraform init -backend=false
terraform -chdir=platform/bootstrap/admin/terraform fmt -check
terraform -chdir=platform/bootstrap/admin/terraform validate
```
