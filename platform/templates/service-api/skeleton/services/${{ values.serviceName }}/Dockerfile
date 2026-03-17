FROM node:22-alpine AS build

WORKDIR /workspace

RUN corepack enable

COPY package.json pnpm-workspace.yaml tsconfig.base.json pnpm-lock.yaml ./
COPY platform/scorecard/package.json platform/scorecard/package.json
COPY services/${{ values.serviceName }}/app/package.json services/${{ values.serviceName }}/app/package.json

RUN pnpm install --frozen-lockfile

COPY services/${{ values.serviceName }}/app services/${{ values.serviceName }}/app

RUN pnpm --filter @paved-road/${{ values.serviceName }} build

FROM node:22-alpine AS runtime

WORKDIR /app
RUN corepack enable

COPY --from=build /workspace/package.json /workspace/pnpm-workspace.yaml /workspace/tsconfig.base.json ./
COPY --from=build /workspace/node_modules ./node_modules
COPY --from=build /workspace/services/${{ values.serviceName }}/app/package.json ./package.json
COPY --from=build /workspace/services/${{ values.serviceName }}/app/dist ./dist

ENV NODE_ENV=production
ENV PORT=${{ values.port }}

CMD ["node", "dist/index.js"]
