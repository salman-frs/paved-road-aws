import { describe, expect, it } from 'vitest';

import { buildServer } from './server.js';

describe('orders-api server', () => {
  it('serves health endpoints', async () => {
    const server = buildServer();

    const health = await server.inject({ method: 'GET', url: '/healthz' });
    const ready = await server.inject({ method: 'GET', url: '/readyz' });
    const live = await server.inject({ method: 'GET', url: '/livez' });

    expect(health.statusCode).toBe(200);
    expect(ready.statusCode).toBe(200);
    expect(live.statusCode).toBe(200);

    await server.close();
  });

  it('exposes metrics', async () => {
    const server = buildServer();

    const metrics = await server.inject({ method: 'GET', url: '/metrics' });

    expect(metrics.statusCode).toBe(200);
    expect(metrics.headers['content-type']).toContain('text/plain');

    await server.close();
  });
});
