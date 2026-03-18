# Backstage Bootstrap Assets

These Helm values are consumed by the Argo-managed Backstage application. Backstage is the self-service entry point and is expected to load `platform/templates/service-api/template.yaml` and authenticate to GitHub with repository PR permissions.

## Notes

- Bootstrap installs only minimal Argo locally.
- Argo then deploys Backstage from the child application at [platform/bootstrap/argocd/apps/backstage.yaml](/Users/salman/codex/paved-road-aws/platform/bootstrap/argocd/apps/backstage.yaml).
- This values file remains the single repo-owned source of truth for the Backstage chart configuration.

Public hostname: `backstage.salmanfrs.dev`
