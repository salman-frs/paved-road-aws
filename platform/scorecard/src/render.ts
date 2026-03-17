import type { ScorecardResult } from './types.js';

const statusIcon = (passed: boolean): string => (passed ? 'PASS' : 'FAIL');

export const renderMarkdown = (result: ScorecardResult): string => {
  const lines: string[] = [];

  lines.push(`# Scorecard: ${result.service.name}`);
  lines.push('');
  lines.push(`Generated at: ${result.generatedAt}`);
  lines.push('');
  lines.push(
    `Summary: ${result.summary.passed}/${result.summary.total} checks passed`,
  );
  lines.push('');

  for (const category of result.categories) {
    lines.push(`## ${category.title} (${statusIcon(category.passed)})`);
    lines.push('');
    lines.push('| Check | Status | Evidence |');
    lines.push('| --- | --- | --- |');

    for (const check of category.checks) {
      lines.push(
        `| ${check.title} | ${statusIcon(check.passed)} | ${check.evidence.join('<br/>')} |`,
      );
    }

    lines.push('');
  }

  return lines.join('\n');
};
