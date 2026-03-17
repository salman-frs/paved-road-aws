import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';

import { parse, stringify } from 'yaml';

type GitOpsValues = {
  image?: {
    repository?: string;
    digest?: string;
  };
  serviceAccount?: {
    roleArn?: string;
  };
  [key: string]: unknown;
};

const option = (flag: string): string | undefined => {
  const index = process.argv.indexOf(flag);
  return index >= 0 ? process.argv[index + 1] : undefined;
};

const required = (value: string | undefined, label: string): string => {
  if (!value) {
    throw new Error(`Missing ${label}`);
  }

  return value;
};

const main = async (): Promise<void> => {
  const repoRoot = process.cwd();
  const valuesPath = required(option('--values-path'), '--values-path');
  const repository = required(option('--repository'), '--repository');
  const digest = required(option('--digest'), '--digest');
  const roleArn = option('--role-arn');

  const filePath = path.resolve(repoRoot, valuesPath);
  const document = parse(await readFile(filePath, 'utf8')) as GitOpsValues;

  document.image = {
    ...(document.image ?? {}),
    repository,
    digest,
  };

  if (roleArn) {
    document.serviceAccount = {
      ...(document.serviceAccount ?? {}),
      roleArn,
    };
  }

  await writeFile(filePath, stringify(document));
};

main().catch((error: unknown) => {
  const message = error instanceof Error ? error.message : 'Unknown error';
  process.stderr.write(`${message}\n`);
  process.exitCode = 1;
});
