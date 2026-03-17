# Backstage Bootstrap Assets

These Helm values deploy Backstage as the self-service entry point. The Backstage instance is expected to load `platform/templates/service-api/template.yaml` and authenticate to GitHub with repository PR permissions.

## Install

```bash
helm repo add backstage https://backstage.github.io/charts
helm upgrade --install backstage backstage/backstage \
  --namespace backstage \
  --create-namespace \
  -f platform/bootstrap/backstage/values.yaml
```

Public hostname: `backstage.salmanfrs.dev`
