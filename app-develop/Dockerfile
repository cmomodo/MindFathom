# syntax=docker/dockerfile:1
# WARNING:  IMPORTANT: Replace your .dockerignore with the generated one from the .dockerignore tab.
# Without it, COPY commands may fail if your existing .dockerignore uses a whitelist.
# --- Stage: Build packages/nc-secret-mgr ---------------------------------------
FROM --platform=$BUILDPLATFORM node:20-alpine3.21 AS packages-nc-secret-mgr-build

WORKDIR /build

# Copy manifests first for better Docker layer caching
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY packages/nc-secret-mgr/package.json ./packages/nc-secret-mgr/package.json
COPY packages/noco-integrations/core/package.json ./packages/noco-integrations/core/package.json
COPY packages/nocodb/package.json ./packages/nocodb/package.json
COPY packages/nocodb-sdk-v2/package.json ./packages/nocodb-sdk-v2/package.json
RUN npm install -g pnpm@9 && pnpm install --frozen-lockfile

# Copy only this service's source - other workspace dirs not needed for this build
COPY packages/nc-secret-mgr/ ./packages/nc-secret-mgr/
RUN CI=false GENERATE_SOURCEMAP=false NODE_OPTIONS=--max-old-space-size=1024 DISABLE_ESLINT_PLUGIN=true pnpm --filter ./packages/nc-secret-mgr build

# --- Stage: Build packages/noco-integrations ---------------------------------------
FROM --platform=$BUILDPLATFORM node:20-alpine3.21 AS packages-noco-integrations-build

WORKDIR /build

COPY packages/noco-integrations/pnpm-lock.yaml packages/noco-integrations/package.json ./
RUN npm install -g pnpm@9 && pnpm install --frozen-lockfile

COPY packages/noco-integrations/ .
RUN pnpm run build

# --- Stage: Build packages/noco-integrations/core ---------------------------------------
FROM --platform=$BUILDPLATFORM node:20-alpine3.21 AS packages-noco-integrations-core-build

WORKDIR /build

# Copy manifests first for better Docker layer caching
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY packages/nc-secret-mgr/package.json ./packages/nc-secret-mgr/package.json
COPY packages/noco-integrations/core/package.json ./packages/noco-integrations/core/package.json
COPY packages/nocodb/package.json ./packages/nocodb/package.json
COPY packages/nocodb-sdk-v2/package.json ./packages/nocodb-sdk-v2/package.json
RUN npm install -g pnpm@9 && pnpm install --frozen-lockfile

# Copy only this service's source - other workspace dirs not needed for this build
COPY packages/noco-integrations/core/ ./packages/noco-integrations/core/
RUN CI=false GENERATE_SOURCEMAP=false NODE_OPTIONS=--max-old-space-size=1024 DISABLE_ESLINT_PLUGIN=true pnpm --filter ./packages/noco-integrations/core build

# --- Stage: Build packages/nocodb ---------------------------------------
FROM --platform=$BUILDPLATFORM node:22-alpine3.21 AS packages-nocodb-build

WORKDIR /build

# Copy manifests first for better Docker layer caching
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY packages/nc-secret-mgr/package.json ./packages/nc-secret-mgr/package.json
COPY packages/noco-integrations/core/package.json ./packages/noco-integrations/core/package.json
COPY packages/nocodb/package.json ./packages/nocodb/package.json
COPY packages/nocodb-sdk-v2/package.json ./packages/nocodb-sdk-v2/package.json
RUN npm install -g pnpm@9 && pnpm install --frozen-lockfile

# Copy only this service's source - other workspace dirs not needed for this build
COPY packages/nocodb/ ./packages/nocodb/
RUN CI=false GENERATE_SOURCEMAP=false NODE_OPTIONS=--max-old-space-size=1024 DISABLE_ESLINT_PLUGIN=true pnpm --filter ./packages/nocodb build

# --- Stage: Build packages/nocodb-sdk-v2 ---------------------------------------
FROM --platform=$BUILDPLATFORM node:20-alpine3.21 AS packages-nocodb-sdk-v2-build

WORKDIR /build

# Copy manifests first for better Docker layer caching
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY packages/nc-secret-mgr/package.json ./packages/nc-secret-mgr/package.json
COPY packages/noco-integrations/core/package.json ./packages/noco-integrations/core/package.json
COPY packages/nocodb/package.json ./packages/nocodb/package.json
COPY packages/nocodb-sdk-v2/package.json ./packages/nocodb-sdk-v2/package.json
RUN npm install -g pnpm@9 && pnpm install --frozen-lockfile

# Copy only this service's source - other workspace dirs not needed for this build
COPY packages/nocodb-sdk-v2/ ./packages/nocodb-sdk-v2/
RUN CI=false GENERATE_SOURCEMAP=false NODE_OPTIONS=--max-old-space-size=1024 DISABLE_ESLINT_PLUGIN=true pnpm --filter ./packages/nocodb-sdk-v2 build

# --- Stage: Build packages/nocodb-sdk -------------------------------------------------
FROM --platform=$BUILDPLATFORM node:18-alpine3.21 AS packages-nocodb-sdk-build

WORKDIR /build

COPY packages/nocodb-sdk/pnpm-lock.yaml packages/nocodb-sdk/package.json ./packages/nocodb-sdk/
RUN npm install -g pnpm@9 && cd packages/nocodb-sdk && pnpm install --frozen-lockfile && pnpm store prune

# Copy root config files needed during build
COPY tsconfig.json ./
COPY packages/nocodb-sdk/ ./packages/nocodb-sdk/
RUN cd packages/nocodb-sdk && pnpm run build

# --- Stage: Runtime packages/nocodb-sdk -----------------------------------------------
FROM node:18-alpine3.21

WORKDIR /app

ENV NODE_ENV=production

COPY packages/nocodb-sdk/pnpm-lock.yaml packages/nocodb-sdk/package.json ./packages/nocodb-sdk/
RUN npm install -g pnpm@9 && cd packages/nocodb-sdk && pnpm install --frozen-lockfile --prod && pnpm store prune

# Copy compiled output from build stage
COPY --from=packages-nocodb-sdk-build /build/packages/nocodb-sdk/dist ./packages/nocodb-sdk/dist
# Copy built packages/nc-secret-mgr assets into server static dir
COPY --from=packages-nc-secret-mgr-build /build/packages/nc-secret-mgr/dist ./packages/nocodb-sdk/public
# Copy built packages/noco-integrations assets into server static dir
COPY --from=packages-noco-integrations-build /build/dist ./packages/nocodb-sdk/public
# Copy built packages/noco-integrations/core assets into server static dir
COPY --from=packages-noco-integrations-core-build /build/packages/noco-integrations/core/dist ./packages/nocodb-sdk/public
# Copy built packages/nocodb assets into server static dir
COPY --from=packages-nocodb-build /build/packages/nocodb/dist ./packages/nocodb-sdk/public
# Copy built packages/nocodb-sdk-v2 assets into server static dir
COPY --from=packages-nocodb-sdk-v2-build /build/packages/nocodb-sdk-v2/dist ./packages/nocodb-sdk/public

RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

STOPSIGNAL SIGTERM
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 CMD wget -qO- http://localhost:3000/health || exit 1
WORKDIR /app/packages/nocodb-sdk
CMD ["node","dist/build/main/index.js"]
