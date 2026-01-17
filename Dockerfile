# Build stage
FROM node:22-bullseye AS builder
WORKDIR /data

# Copy manifests first for caching
COPY package.json pnpm-lock.yaml ./

# Install dependencies (include devDependencies for TypeScript build)
RUN npm install -g pnpm && \
    pnpm install --no-frozen-lockfile

# Copy the rest of the source (packages, tsconfig, etc.)
COPY . .

# Build
RUN pnpm run build

# Production stage
FROM node:22-bullseye AS production
WORKDIR /data

# Copy only what’s needed from builder
COPY --from=builder /data/dist ./dist
COPY --from=builder /data/node_modules ./node_modules
COPY --from=builder /data/package.json ./package.json

ENV NODE_ENV=production

CMD ["node", "dist/index.js"]
