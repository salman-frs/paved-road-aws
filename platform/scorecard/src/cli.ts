import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';

import { evaluateService } from './evaluate.js';
import { renderMarkdown } from './render.js';

const readOption = (flag: string): string | undefined => {
  const index = process.argv.indexOf(flag);
  return index >= 0 ? process.argv[index + 1] : undefined;
};

const required = (value: string | undefined, message: string): string => {
  if (!value) {
    throw new Error(message);
  }

  return value;
};

const main = async (): Promise<void> => {
  const repoRoot = process.cwd();
  const servicePath = required(
    readOption('--service-path'),
    'Missing --service-path',
  );
  const serviceName = required(
    readOption('--service-name'),
    'Missing --service-name',
  );
  const outputDir =
    readOption('--output-dir') ??
    path.join('platform', 'scorecard', 'output', serviceName);
  const markdownPath =
    readOption('--markdown-path') ??
    path.join(servicePath, 'docs', 'scorecard.md');

  const result = await evaluateService(repoRoot, servicePath, serviceName, {
    ciStatus:
      (readOption('--ci-status') as 'pass' | 'fail' | undefined) ?? 'pass',
    securityStatus:
      (readOption('--security-status') as 'pass' | 'fail' | undefined) ??
      'pass',
    iacStatus:
      (readOption('--iac-status') as 'pass' | 'fail' | undefined) ?? 'pass',
  });

  const markdown = renderMarkdown(result);

  await mkdir(path.resolve(repoRoot, outputDir), { recursive: true });
  await mkdir(path.resolve(repoRoot, path.dirname(markdownPath)), {
    recursive: true,
  });

  await writeFile(
    path.resolve(repoRoot, outputDir, 'scorecard.json'),
    JSON.stringify(result, null, 2),
  );
  await writeFile(path.resolve(repoRoot, outputDir, 'scorecard.md'), markdown);
  await writeFile(path.resolve(repoRoot, markdownPath), markdown);

  process.stdout.write(`${JSON.stringify(result.summary)}\n`);
};

main().catch((error: unknown) => {
  const message = error instanceof Error ? error.message : 'Unknown error';
  process.stderr.write(`${message}\n`);
  process.exitCode = 1;
});
