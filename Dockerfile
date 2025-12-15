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
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create non-root user with explicit UID for consistent file permissions
RUN useradd --create-home --shell /bin/bash --uid 1000 developer

# Switch to non-root user
USER developer

# Configure npm to install global packages in user space
ENV NPM_CONFIG_PREFIX=/home/developer/.npm-global
ENV PATH="/home/developer/.npm-global/bin:${PATH}"

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code \
    && npm cache clean --force

WORKDIR /workspace

# Update Claude Code on start, then run it
ENTRYPOINT ["sh", "-c", "npm update -g @anthropic-ai/claude-code 2>/dev/null || true; exec claude"]
