import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    include: ['platform/**/*.test.ts', 'services/**/*.test.ts'],
    exclude: [
      '**/dist/**',
      '**/node_modules/**',
      '**/.pnpm/**',
      '**/.terraform/**',
    ],
  },
});
