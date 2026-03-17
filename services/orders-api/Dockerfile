FROM node:22-alpine AS build

WORKDIR /workspace

RUN corepack enable

COPY package.json pnpm-workspace.yaml tsconfig.base.json pnpm-lock.yaml ./
COPY platform/scorecard/package.json platform/scorecard/package.json
COPY services/orders-api/app/package.json services/orders-api/app/package.json

RUN pnpm install --frozen-lockfile

COPY services/orders-api/app services/orders-api/app

RUN pnpm --filter @paved-road/orders-api build

FROM node:22-alpine AS runtime

WORKDIR /app

COPY --from=build /workspace/services/orders-api/app/package.json ./package.json
COPY --from=build /workspace/services/orders-api/app/dist ./dist
COPY --from=build /workspace/node_modules ./node_modules

ENV NODE_ENV=production
ENV PORT=3000

CMD ["node", "dist/index.js"]
