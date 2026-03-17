# AWS Internal Developer Platform Portfolio

This repository is an opinionated internal developer platform reference implementation on AWS. It demonstrates one paved road for creating and shipping production-ready TypeScript HTTP APIs to EKS with Backstage, Terraform, GitHub Actions, ArgoCD, baseline observability, and a CI-derived service scorecard.

## Repository Shape

```text
platform/
  bootstrap/        Shared AWS and cluster prerequisites for the demo
  modules/          Reusable Terraform modules owned by the platform
  templates/        Backstage scaffolder template and template contract tests
  scorecard/        Evidence-based scorecard engine and schema

services/
  orders-api/       Golden-path generated example service

gitops/
  dev/              ArgoCD Application manifests and environment values
  prod/

.github/workflows/  PR, service delivery, and bootstrap workflows
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

## Local Commands

```bash
pnpm install
pnpm lint
pnpm test
pnpm typecheck
pnpm build
pnpm scorecard --service-path services/orders-api --service-name orders-api
terraform -chdir=platform/bootstrap/terraform init -backend=false
terraform -chdir=platform/bootstrap/terraform validate
terraform -chdir=services/orders-api/infra init -backend=false
terraform -chdir=services/orders-api/infra validate
```

## What Is Implemented Here

- Bootstrap Terraform for the demo EKS foundation, core EKS addons, bootstrap operator cluster access, GitHub OIDC, and shared state primitives
- Reusable per-service Terraform module with IRSA, ECR, optional Cloudflare DNS, and one optional backing dependency
- Backstage scaffolder template that opens a PR against the monorepo
- A fully scaffolded reference service in `services/orders-api/`
- GitOps manifests for ArgoCD per-service deployment
- Baseline Grafana dashboard, Prometheus alerts, and scorecard generation
