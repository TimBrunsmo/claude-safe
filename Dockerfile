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

# Install Bun globally
ENV BUN_INSTALL="/usr/local/bun"
RUN curl -fsSL https://bun.sh/install | bash \
    && ln -s /usr/local/bun/bin/bun /usr/local/bin/bun \
    && ln -s /usr/local/bun/bin/bunx /usr/local/bin/bunx

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
ENTRYPOINT ["sh", "-c", "if [ ! -s /home/node/.claude/.claude.json.persistent ]; then echo '{}' > /home/node/.claude/.claude.json.persistent; fi && ln -sf /home/node/.claude/.claude.json.persistent /home/node/.claude.json && npm update -g @anthropic-ai/claude-code 2>/dev/null || true; exec claude \"$@\"", "--"]
