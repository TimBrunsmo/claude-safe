# claude-safe - Isolated Claude Code Environment
# https://github.com/timbrunsmo/claude-safe

FROM node:22-slim

LABEL org.opencontainers.image.title="claude-isolated"
LABEL org.opencontainers.image.description="Isolated Claude Code development environment"
LABEL org.opencontainers.image.source="https://github.com/timbrunsmo/claude-safe"

# Install minimal dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        curl \
        ca-certificates \
        unzip \
        inotify-tools \
        lsof \
        procps \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install Bun v1.3.10 from GitHub release with checksum verification
RUN BUN_VERSION="1.3.10" \
    && ARCH=$(dpkg --print-architecture) \
    && if [ "$ARCH" = "amd64" ]; then BUN_ARCH="x64"; BUN_SHA256="f57bc0187e39623de716ba3a389fda5486b2d7be7131a980ba54dc7b733d2e08"; \
       elif [ "$ARCH" = "arm64" ]; then BUN_ARCH="aarch64"; BUN_SHA256="fa5ecb25cafa8e8f5c87a0f833719d46dd0af0a86c7837d806531212d55636d3"; else echo "Unsupported architecture: $ARCH" >&2; exit 1; fi \
    && curl -fsSL -o /tmp/bun.zip "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-${BUN_ARCH}.zip" \
    && echo "${BUN_SHA256}  /tmp/bun.zip" | sha256sum -c - \
    && unzip -q /tmp/bun.zip -d /tmp/bun \
    && mv /tmp/bun/bun-linux-${BUN_ARCH}/bun /usr/local/bin/bun \
    && ln -s /usr/local/bin/bun /usr/local/bin/bunx \
    && rm -rf /tmp/bun.zip /tmp/bun

# Use existing node user (UID 1000) from base image
USER node

# Configure npm to install global packages in user space
ENV NPM_CONFIG_PREFIX=/home/node/.npm-global
ENV PATH="/home/node/.npm-global/bin:${PATH}"

# Force polling for file watchers — fixes hot reload in Docker bind mounts
ENV CHOKIDAR_USEPOLLING=true
ENV WATCHPACK_POLLING=true

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code \
    && npm cache clean --force

RUN mkdir -p /home/node/.claude

WORKDIR /workspace

# Persist .claude.json via symlink into the volume, then start Claude Code
ENTRYPOINT ["sh", "-c", "if [ ! -s /home/node/.claude/.claude.json.persistent ]; then echo '{}' > /home/node/.claude/.claude.json.persistent; fi; ln -sf /home/node/.claude/.claude.json.persistent /home/node/.claude.json; (npm update -g @anthropic-ai/claude-code 2>/dev/null || true); exec claude \"$@\"", "--"]
