# AWS Internal Developer Platform Portfolio

This repository is an opinionated internal developer platform reference implementation on AWS. It demonstrates one paved road for creating and shipping production-ready TypeScript HTTP APIs to EKS with Backstage, Terraform, GitHub Actions, ArgoCD, baseline observability, and a CI-derived service scorecard.

## Repository Shape

```text
platform/
  bootstrap/        Local-first bootstrap states, Argo bootstrap assets, and platform values
  modules/          Reusable Terraform modules owned by the platform
  templates/        Backstage scaffolder template and template contract tests
  scorecard/        Evidence-based scorecard engine and schema

services/
  orders-api/       Golden-path generated example service

gitops/
  dev/              ArgoCD Application manifests and environment values
  prod/

.github/workflows/  PR and service delivery workflows
```

## Ownership Boundaries

- `platform/bootstrap/` owns shared demo infrastructure and platform-adjacent installs.
- `platform/modules/service-stack/` owns per-service AWS resources only.
- `services/<service>/` owns application code, chart, docs, dashboards, alerts, and service-local Terraform inputs.
- `gitops/<env>/<service>/` owns deployable desired state only.
- `platform/scorecard/` owns service-quality rules and rendering.

## Naming Conventions

- Service names: kebab-case, DNS-safe, one service per top-level directory under `services/`
- Environments: `dev`, `prod`
- Kubernetes namespaces: `<service>-<environment>`
- Helm release names: `<service>-<environment>`
- AWS tags: `Project`, `Environment`, `Service`, `ManagedBy`
- Secret paths: `/<project>/<environment>/<service>/app`
- Public DNS: `*.salmanfrs.dev` managed in Cloudflare, with `ingress.dev.salmanfrs.dev` as the DNS-only ingress anchor

## Tooling

- Package manager: `pnpm`
- Application language: TypeScript
- Test runner: `vitest`
- Linting and formatting: `biome`
- Infrastructure: Terraform
- Deployment packaging: Helm
- Operator task runner: `just`

## Operator Prerequisites

Bootstrap and destroy are local operator workflows. Before using the bootstrap commands, have these available on the machine running them:

- `aws`, `terraform`, `kubectl`, `helm`, and `just`
- AWS credentials with enough access to create the bootstrap admin and cluster resources
- `CLOUDFLARE_API_TOKEN` exported when publishing DNS
- access to `salman-frs/paved-road-aws` so Backstage and Argo can point at the final repo URL

## Local Commands

```bash
pnpm install
pnpm lint
pnpm test
pnpm typecheck
pnpm build
pnpm scorecard --service-path services/orders-api --service-name orders-api
terraform -chdir=platform/bootstrap/admin/terraform init -backend=false
terraform -chdir=platform/bootstrap/admin/terraform validate
terraform -chdir=platform/bootstrap/cluster/terraform init -backend=false
terraform -chdir=platform/bootstrap/cluster/terraform validate
terraform -chdir=services/orders-api/infra init -backend=false
terraform -chdir=services/orders-api/infra validate
```

## What Is Implemented Here

- Bootstrap Terraform for the demo EKS foundation, core EKS addons, bootstrap operator cluster access, GitHub OIDC, and shared state primitives, using the AWS-owned default key path for EKS secret encryption
- Reusable per-service Terraform module with IRSA, ECR, optional Cloudflare DNS, and one optional backing dependency
- Backstage scaffolder template that opens a PR against the monorepo
- A fully scaffolded reference service in `services/orders-api/`
- GitOps manifests for ArgoCD per-service deployment
- Baseline Grafana dashboard, Prometheus alerts, and scorecard generation

## Bootstrap UX

Bootstrap and destroy are local operator workflows.

- `platform/bootstrap/admin/terraform` is the persistent admin state
- `platform/bootstrap/cluster/terraform` is the disposable cluster state
- `platform/bootstrap/argocd/` contains the minimal Argo bootstrap and app-of-apps manifests
- `justfile` is the supported operator command surface

Recommended order:

1. `just bootstrap-admin-init`
2. `just bootstrap-admin-apply`
3. `just bootstrap-cluster-init`
4. `just bootstrap-cluster-apply`
5. `just bootstrap-kubeconfig`
6. `just bootstrap-argocd`
7. `just bootstrap-dns`

After bootstrap is complete, GitHub Actions takes over only for day-2 service delivery:

- PR validation via [/.github/workflows/pr.yml](/Users/salman/codex/paved-road-aws/.github/workflows/pr.yml)
- service delivery via [/.github/workflows/service-delivery.yml](/Users/salman/codex/paved-road-aws/.github/workflows/service-delivery.yml)

## Destroy Note

Bootstrap install assets such as `ingress-nginx`, Backstage, and observability are reconciled on top of the EKS cluster. Teardown must remove those applications before destroying the bootstrap VPC, or AWS load balancer artifacts can block subnet and VPC deletion. Use [platform/bootstrap/README.md](/Users/salman/codex/paved-road-aws/platform/bootstrap/README.md) and `just destroy` for the supported destroy path.
