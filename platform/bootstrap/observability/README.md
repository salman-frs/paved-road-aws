# Observability Bootstrap Assets

The platform bootstrap exposes shared telemetry backends and collection primitives through Argo-managed Helm releases:

- `kube-prometheus-stack` for Prometheus and Grafana
- OpenTelemetry Collector for OTLP ingestion and export

## Notes

- Bootstrap installs only minimal Argo locally.
- Argo then deploys the observability releases from:
  - [platform/bootstrap/argocd/apps/kube-prometheus-stack.yaml](/Users/salman/codex/paved-road-aws/platform/bootstrap/argocd/apps/kube-prometheus-stack.yaml)
  - [platform/bootstrap/argocd/apps/otel-collector.yaml](/Users/salman/codex/paved-road-aws/platform/bootstrap/argocd/apps/otel-collector.yaml)
- These values files remain the single repo-owned source of truth for observability chart configuration.

Public Grafana hostname: `grafana.salmanfrs.dev`
