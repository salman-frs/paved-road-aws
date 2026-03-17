import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';

import { parse } from 'yaml';

import type {
  EvidenceOptions,
  ScorecardCategory,
  ScorecardCheck,
  ScorecardResult,
} from './types.js';

type CatalogInfo = {
  metadata?: {
    annotations?: Record<string, string>;
  };
  spec?: {
    owner?: string;
    system?: string;
  };
};

const fileExists = async (filePath: string): Promise<boolean> => {
  try {
    await readFile(filePath);
    return true;
  } catch {
    return false;
  }
};

const directoryHasFiles = async (
  dirPath: string,
  suffixes: string[],
): Promise<boolean> => {
  try {
    const entries = await readdir(dirPath, { withFileTypes: true });
    return entries.some(
      (entry) =>
        entry.isFile() &&
        suffixes.some((suffix) => entry.name.endsWith(suffix)),
    );
  } catch {
    return false;
  }
};

const buildCheck = (
  id: string,
  title: string,
  passed: boolean,
  message: string,
  evidence: string[],
): ScorecardCheck => ({
  id,
  title,
  passed,
  message,
  evidence,
});

export const evaluateService = async (
  repoRoot: string,
  servicePath: string,
  serviceName: string,
  options: EvidenceOptions = {},
): Promise<ScorecardResult> => {
  const absoluteServicePath = path.resolve(repoRoot, servicePath);
  const catalogPath = path.join(absoluteServicePath, 'catalog-info.yaml');
  const catalogEvidencePath = path.join(servicePath, 'catalog-info.yaml');
  const readmePath = path.join(absoluteServicePath, 'README.md');
  const readmeEvidencePath = path.join(servicePath, 'README.md');
  const runbookPath = path.join(absoluteServicePath, 'docs', 'runbook.md');
  const runbookEvidencePath = path.join(servicePath, 'docs', 'runbook.md');
  const dashboardDir = path.join(absoluteServicePath, 'dashboards');
  const dashboardEvidencePath = path.join(servicePath, 'dashboards');
  const alertsDir = path.join(absoluteServicePath, 'alerts');
  const alertsEvidencePath = path.join(servicePath, 'alerts');
  const appPackagePath = path.join(absoluteServicePath, 'app', 'package.json');
  const appPackageEvidencePath = path.join(servicePath, 'app', 'package.json');
  const serverPath = path.join(absoluteServicePath, 'app', 'src', 'server.ts');
  const serverEvidencePath = path.join(servicePath, 'app', 'src', 'server.ts');
  const telemetryPath = path.join(
    absoluteServicePath,
    'app',
    'src',
    'telemetry.ts',
  );
  const telemetryEvidencePath = path.join(
    servicePath,
    'app',
    'src',
    'telemetry.ts',
  );
  const infraPath = path.join(absoluteServicePath, 'infra', 'main.tf');
  const infraEvidencePath = path.join(servicePath, 'infra', 'main.tf');
  const chartPath = path.join(absoluteServicePath, 'chart', 'Chart.yaml');
  const chartEvidencePath = path.join(servicePath, 'chart', 'Chart.yaml');
  const gitopsPath = path.join(
    repoRoot,
    'gitops',
    'dev',
    serviceName,
    'application.yaml',
  );
  const gitopsEvidencePath = path.join(
    'gitops',
    'dev',
    serviceName,
    'application.yaml',
  );
  const prWorkflowPath = path.join(repoRoot, '.github', 'workflows', 'pr.yml');
  const prWorkflowEvidencePath = path.join('.github', 'workflows', 'pr.yml');

  const catalog = parse(await readFile(catalogPath, 'utf8')) as CatalogInfo;
  const serverSource = await readFile(serverPath, 'utf8');
  const telemetrySource = await readFile(telemetryPath, 'utf8');
  const packageJson = JSON.parse(await readFile(appPackagePath, 'utf8')) as {
    dependencies?: Record<string, string>;
  };

  const metadataChecks = [
    buildCheck(
      'owner-metadata',
      'Owner metadata declared',
      Boolean(catalog?.spec?.owner),
      catalog?.spec?.owner
        ? `Owner set to ${catalog.spec.owner}.`
        : 'Service owner is missing from catalog-info.',
      [catalogEvidencePath],
    ),
    buildCheck(
      'system-metadata',
      'System metadata declared',
      Boolean(catalog?.spec?.system),
      catalog?.spec?.system
        ? `System set to ${catalog.spec.system}.`
        : 'Service system is missing from catalog-info.',
      [catalogEvidencePath],
    ),
    buildCheck(
      'runbook-reference',
      'Runbook reference annotation present',
      Boolean(catalog?.metadata?.annotations?.['portfolio.io/runbook']),
      catalog?.metadata?.annotations?.['portfolio.io/runbook']
        ? 'Runbook annotation is present.'
        : 'Runbook annotation is missing.',
      [catalogEvidencePath],
    ),
  ];

  const docsChecks = [
    buildCheck(
      'readme-present',
      'Service README exists',
      await fileExists(readmePath),
      (await fileExists(readmePath)) ? 'README exists.' : 'README is missing.',
      [readmeEvidencePath],
    ),
    buildCheck(
      'runbook-present',
      'Runbook exists',
      await fileExists(runbookPath),
      (await fileExists(runbookPath))
        ? 'Runbook exists.'
        : 'Runbook is missing.',
      [runbookEvidencePath],
    ),
    buildCheck(
      'dashboard-assets',
      'Dashboard assets exist',
      await directoryHasFiles(dashboardDir, ['.json']),
      (await directoryHasFiles(dashboardDir, ['.json']))
        ? 'Dashboard assets found.'
        : 'No dashboard JSON found.',
      [dashboardEvidencePath],
    ),
    buildCheck(
      'alert-assets',
      'Alert rules exist',
      await directoryHasFiles(alertsDir, ['.yaml', '.yml']),
      (await directoryHasFiles(alertsDir, ['.yaml', '.yml']))
        ? 'Alert assets found.'
        : 'No alert rules found.',
      [alertsEvidencePath],
    ),
  ];

  const runtimeChecks = [
    buildCheck(
      'health-probes',
      'Health, readiness, and liveness routes exist',
      ['/healthz', '/readyz', '/livez'].every(
        (route) =>
          serverSource.includes(`'${route}'`) ||
          serverSource.includes(`"${route}"`),
      ),
      'Application source contains all three probe routes.',
      [serverEvidencePath],
    ),
    buildCheck(
      'metrics-endpoint',
      'Prometheus metrics endpoint exists',
      serverSource.includes('/metrics'),
      serverSource.includes('/metrics')
        ? 'Metrics route found.'
        : 'Metrics route missing.',
      [serverEvidencePath],
    ),
    buildCheck(
      'tracing-enabled',
      'OpenTelemetry is wired into the service',
      telemetrySource.includes('NodeSDK') &&
        Boolean(packageJson.dependencies?.['@opentelemetry/sdk-node']) &&
        Boolean(
          packageJson.dependencies?.['@opentelemetry/exporter-trace-otlp-http'],
        ),
      telemetrySource.includes('NodeSDK')
        ? 'Telemetry bootstrap found.'
        : 'Telemetry bootstrap missing.',
      [telemetryEvidencePath, appPackageEvidencePath],
    ),
  ];

  const deliveryChecks = [
    buildCheck(
      'pr-workflow',
      'PR workflow exists',
      await fileExists(prWorkflowPath),
      (await fileExists(prWorkflowPath))
        ? 'PR workflow exists.'
        : 'PR workflow missing.',
      [prWorkflowEvidencePath],
    ),
    buildCheck(
      'terraform-wrapper',
      'Service Terraform wrapper exists',
      await fileExists(infraPath),
      (await fileExists(infraPath))
        ? 'Service Terraform wrapper exists.'
        : 'Service Terraform wrapper missing.',
      [infraEvidencePath],
    ),
    buildCheck(
      'gitops-application',
      'GitOps Application manifest exists',
      await fileExists(gitopsPath),
      (await fileExists(gitopsPath))
        ? 'GitOps Application manifest exists.'
        : 'GitOps Application manifest missing.',
      [gitopsEvidencePath],
    ),
    buildCheck(
      'chart-present',
      'Helm chart exists',
      await fileExists(chartPath),
      (await fileExists(chartPath))
        ? 'Helm chart exists.'
        : 'Helm chart missing.',
      [chartEvidencePath],
    ),
    buildCheck(
      'ci-results',
      'CI, security, and IaC checks passed',
      (options.ciStatus ?? 'pass') === 'pass' &&
        (options.securityStatus ?? 'pass') === 'pass' &&
        (options.iacStatus ?? 'pass') === 'pass',
      `CI=${options.ciStatus ?? 'pass'}, security=${options.securityStatus ?? 'pass'}, iac=${options.iacStatus ?? 'pass'}.`,
      [prWorkflowEvidencePath, infraEvidencePath],
    ),
  ];

  const categories: ScorecardCategory[] = [
    {
      id: 'metadata',
      title: 'Metadata completeness',
      passed: metadataChecks.every((check) => check.passed),
      checks: metadataChecks,
    },
    {
      id: 'docs',
      title: 'Docs, dashboards, and alerts',
      passed: docsChecks.every((check) => check.passed),
      checks: docsChecks,
    },
    {
      id: 'runtime',
      title: 'Runtime instrumentation',
      passed: runtimeChecks.every((check) => check.passed),
      checks: runtimeChecks,
    },
    {
      id: 'delivery',
      title: 'Delivery and deployment path',
      passed: deliveryChecks.every((check) => check.passed),
      checks: deliveryChecks,
    },
  ];

  const flatChecks = categories.flatMap((category) => category.checks);

  return {
    schemaVersion: 'v1',
    generatedAt: new Date().toISOString(),
    service: {
      name: serviceName,
      path: servicePath,
    },
    summary: {
      total: flatChecks.length,
      passed: flatChecks.filter((check) => check.passed).length,
      failed: flatChecks.filter((check) => !check.passed).length,
    },
    categories,
  };
};
