# Backstage Service Template

This template generates one paved-road TypeScript HTTP API service into the monorepo and opens a pull request instead of writing to the default branch.

## Inputs

- `serviceName`
- `owner`
- `system`
- `port`
- `includeBackingDependency`

## Generated Assets

- `services/<service-name>/app/`
- `services/<service-name>/chart/`
- `services/<service-name>/infra/`
- `services/<service-name>/catalog-info.yaml`
- `services/<service-name>/dashboards/`
- `services/<service-name>/alerts/`
- `services/<service-name>/docs/runbook.md`
- `gitops/dev/<service-name>/`

## Contract Testing

Template tests render the skeleton locally and verify file layout plus metadata output.
