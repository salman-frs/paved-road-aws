import { cp, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';

import { afterEach, describe, expect, it } from 'vitest';

import { evaluateService } from './evaluate.js';
import { renderMarkdown } from './render.js';

const tempDirs: string[] = [];
const repoRoot = path.resolve(process.cwd());

const copyFixtureFile = async (
  tempRoot: string,
  ...relativePath: string[]
): Promise<void> => {
  const sourcePath = path.join(repoRoot, ...relativePath);
  const targetPath = path.join(tempRoot, ...relativePath);

  await cp(sourcePath, targetPath, { recursive: true });
};

describe('scorecard evaluation', () => {
  afterEach(async () => {
    await Promise.all(
      tempDirs.map((dir) => rm(dir, { recursive: true, force: true })),
    );
    tempDirs.length = 0;
  });

  it('passes for the demo service', async () => {
    const result = await evaluateService(
      repoRoot,
      'services/orders-api',
      'orders-api',
    );

    expect(result.summary.failed).toBe(0);
    expect(renderMarkdown(result)).toContain('Scorecard: orders-api');
  });

  it('fails when the runbook is missing', async () => {
    const tempRoot = await mkdtemp(
      path.join(os.tmpdir(), 'scorecard-fixture-'),
    );
    tempDirs.push(tempRoot);

    await Promise.all([
      copyFixtureFile(tempRoot, '.github'),
      copyFixtureFile(tempRoot, 'gitops', 'dev', 'orders-api'),
      copyFixtureFile(tempRoot, 'services', 'orders-api'),
    ]);

    await rm(
      path.join(tempRoot, 'services', 'orders-api', 'docs', 'runbook.md'),
    );
    const result = await evaluateService(
      tempRoot,
      'services/orders-api',
      'orders-api',
    );

    expect(result.summary.failed).toBeGreaterThan(0);
    expect(
      result.categories.find((category) => category.id === 'docs')?.passed,
    ).toBe(false);

    const markdown = renderMarkdown(result);
    expect(markdown).toContain('FAIL');
    await writeFile(path.join(tempRoot, 'tmp-scorecard.md'), markdown);
    expect(
      await readFile(path.join(tempRoot, 'tmp-scorecard.md'), 'utf8'),
    ).toContain('Runbook exists');
  }, 15000);
});
