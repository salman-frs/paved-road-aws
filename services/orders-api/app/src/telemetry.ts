import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { resourceFromAttributes } from '@opentelemetry/resources';
import { NodeSDK } from '@opentelemetry/sdk-node';
import {
  ATTR_SERVICE_NAME,
  ATTR_SERVICE_VERSION,
  SEMRESATTRS_DEPLOYMENT_ENVIRONMENT,
} from '@opentelemetry/semantic-conventions';

export const startTelemetry = (): NodeSDK => {
  const serviceName = process.env.OTEL_SERVICE_NAME ?? 'orders-api';
  const serviceVersion = process.env.SERVICE_VERSION ?? '0.1.0';
  const environment = process.env.APP_ENV ?? 'dev';
  const endpoint =
    process.env.OTEL_EXPORTER_OTLP_TRACES_ENDPOINT ??
    'http://otel-collector.observability.svc.cluster.local:4318/v1/traces';

  const sdk = new NodeSDK({
    resource: resourceFromAttributes({
      [ATTR_SERVICE_NAME]: serviceName,
      [ATTR_SERVICE_VERSION]: serviceVersion,
      [SEMRESATTRS_DEPLOYMENT_ENVIRONMENT]: environment,
    }),
    traceExporter: new OTLPTraceExporter({ url: endpoint }),
    instrumentations: [getNodeAutoInstrumentations()],
  });

  sdk.start();

  return sdk;
};
