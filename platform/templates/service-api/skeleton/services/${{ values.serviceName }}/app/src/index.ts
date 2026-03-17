import { buildServer } from './server.js';
import { startTelemetry } from './telemetry.js';

const port = Number.parseInt(process.env.PORT ?? `${{ values.port }}`, 10);
const host = process.env.HOST ?? '0.0.0.0';

const telemetry = startTelemetry();
const server = buildServer();

const stop = async (): Promise<void> => {
  await server.close();
  await telemetry.shutdown();
};

process.on('SIGINT', () => {
  void stop().finally(() => process.exit(0));
});

process.on('SIGTERM', () => {
  void stop().finally(() => process.exit(0));
});

server
  .listen({ host, port })
  .then(() => {
    server.log.info({ port }, 'service started');
  })
  .catch(async (error: unknown) => {
    server.log.error({ error }, 'service failed to start');
    await telemetry.shutdown();
    process.exit(1);
  });
