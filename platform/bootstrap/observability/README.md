# Observability Bootstrap Assets

The platform bootstrap installs shared telemetry backends and collection primitives:

- `kube-prometheus-stack` for Prometheus and Grafana
- OpenTelemetry Collector for OTLP ingestion and export

## Install

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace observability \
  --create-namespace \
  -f platform/bootstrap/observability/kube-prometheus-values.yaml

helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
  --namespace observability \
  -f platform/bootstrap/observability/otel-collector-values.yaml
```

Public Grafana hostname: `grafana.salmanfrs.dev`
