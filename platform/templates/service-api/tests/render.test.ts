import {
  mkdir,
  mkdtemp,
  readdir,
  readFile,
  rm,
  stat,
  writeFile,
} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';

import { afterEach, describe, expect, it } from 'vitest';
import { parse } from 'yaml';

const tempDirs: string[] = [];

const renderValue = (input: string, values: Record<string, string>): string =>
  Object.entries(values).reduce(
    (accumulator, [key, value]) =>
      accumulator.replaceAll(`\${{ values.${key} }}`, value),
    input,
  );

const renderDirectory = async (
  sourceDir: string,
  destinationDir: string,
  values: Record<string, string>,
): Promise<void> => {
  const entries = await readdir(sourceDir, { withFileTypes: true });

  for (const entry of entries) {
    const renderedName = renderValue(entry.name, values);
    const sourcePath = path.join(sourceDir, entry.name);
    const destinationPath = path.join(destinationDir, renderedName);

    if (entry.isDirectory()) {
      await stat(destinationDir).catch(async () => {
        await mkdir(destinationDir, { recursive: true });
      });
      await mkdir(destinationPath, { recursive: true });
      await renderDirectory(sourcePath, destinationPath, values);
      continue;
    }

    const source = await readFile(sourcePath, 'utf8');
    await writeFile(destinationPath, renderValue(source, values));
  }
};

describe('service-api template', () => {
  afterEach(async () => {
    await Promise.all(
      tempDirs.map((dir) => rm(dir, { recursive: true, force: true })),
    );
    tempDirs.length = 0;
  });

  it('renders the required service and gitops assets', async () => {
    const tempRoot = await mkdtemp(path.join(os.tmpdir(), 'template-render-'));
    tempDirs.push(tempRoot);

    await renderDirectory(
      path.resolve(process.cwd(), 'platform/templates/service-api/skeleton'),
      tempRoot,
      {
        serviceName: 'billing-api',
        owner: 'group:default/platform',
        system: 'billing',
        port: '3000',
        backingDependency: 'sqs',
      },
    );

    const requiredPaths = [
      'services/billing-api/app/package.json',
      'services/billing-api/chart/Chart.yaml',
      'services/billing-api/infra/main.tf',
      'services/billing-api/catalog-info.yaml',
      'services/billing-api/dashboards/service-overview.json',
      'services/billing-api/alerts/prometheus-rules.yaml',
      'services/billing-api/docs/runbook.md',
      'gitops/dev/billing-api/application.yaml',
    ];

    for (const relativePath of requiredPaths) {
      await expect(
        stat(path.join(tempRoot, relativePath)),
      ).resolves.toBeTruthy();
    }

    const catalog = parse(
      await readFile(
        path.join(tempRoot, 'services/billing-api/catalog-info.yaml'),
        'utf8',
      ),
    ) as {
      spec?: { owner?: string; system?: string };
    };

    expect(catalog.spec?.owner).toBe('group:default/platform');
    expect(catalog.spec?.system).toBe('billing');

    const infra = await readFile(
      path.join(
        tempRoot,
        'services/billing-api/infra/terraform.tfvars.example',
      ),
      'utf8',
    );
    expect(infra).toMatch(/backing_dependency\s+=\s+"sqs"/);
  });

  it('renders without the optional backing dependency', async () => {
    const tempRoot = await mkdtemp(path.join(os.tmpdir(), 'template-render-'));
    tempDirs.push(tempRoot);

    await renderDirectory(
      path.resolve(process.cwd(), 'platform/templates/service-api/skeleton'),
      tempRoot,
      {
        serviceName: 'catalog-api',
        owner: 'group:default/catalog',
        system: 'catalog',
        port: '8080',
        backingDependency: 'none',
      },
    );

    const infra = await readFile(
      path.join(
        tempRoot,
        'services/catalog-api/infra/terraform.tfvars.example',
      ),
      'utf8',
    );
    expect(infra).toMatch(/backing_dependency\s+=\s+"none"/);
  });
});
