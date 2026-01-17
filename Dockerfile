# Build stage
FROM node:22-bullseye-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /data

# Copy dependency manifests and tsconfig first
COPY package.json pnpm-lock.yaml tsconfig.json ./

# Install dependencies
RUN npm install -g pnpm && \
    pnpm install --no-frozen-lockfile

# Copy the rest of the source
COPY . .

# Build
RUN pnpm run build

# Production stage
FROM node:22-bullseye-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    sqlite3 \
    tini \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /data

# Copy built app from builder
COPY --from=builder /data /data

# Link n8n binary
RUN ln -s /data/packages/cli/bin/n8n /usr/local/bin/n8n

# Environment
ENV NODE_ENV=production
ENV N8N_PORT=5678
EXPOSE 5678

USER node

ENTRYPOINT ["tini", "--", "n8n"]
