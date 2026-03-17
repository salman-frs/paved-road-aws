import Fastify, { type FastifyInstance } from 'fastify';
import { collectDefaultMetrics, Registry } from 'prom-client';

export const buildServer = (): FastifyInstance => {
  const app = Fastify({
    logger: {
      level: process.env.LOG_LEVEL ?? 'info',
      base: {
        service: process.env.OTEL_SERVICE_NAME ?? 'orders-api',
        environment: process.env.APP_ENV ?? 'dev',
      },
    },
  });

  const registry = new Registry();
  collectDefaultMetrics({ register: registry });

  app.get('/', async () => ({
    service: process.env.OTEL_SERVICE_NAME ?? 'orders-api',
    environment: process.env.APP_ENV ?? 'dev',
    status: 'ok',
  }));

  app.get('/healthz', async () => ({ status: 'ok' }));
  app.get('/readyz', async () => ({ status: 'ready' }));
  app.get('/livez', async () => ({ status: 'live' }));

  app.get('/metrics', async (_request, reply) => {
    reply.header('content-type', registry.contentType);
    return registry.metrics();
  });

  return app;
};
