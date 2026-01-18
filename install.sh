#!/usr/bin/env bash
#
# claude-safe installer
# https://github.com/timbrunsmo/claude-safe
#
# Run isolated Claude Code sessions in Docker containers.
# Protects your system from supply chain attacks.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/timbrunsmo/claude-safe/main/install.sh | bash
#
# What this script does:
#   1. Checks that Docker is installed and running
#   2. Creates ~/.claude/docker/Dockerfile.isolated
#   3. Builds a Docker image called "claude-isolated"
#   4. Creates shell function files at ~/.claude/claude-safe.{fish,bash,zsh}
#   5. Prints instructions - YOU decide whether to source them
#
# This script does NOT modify your shell config. You do that yourself.
#
# Requirements:
#   - Docker Desktop or OrbStack (running)
#

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

check_prerequisites() {
    info "Checking prerequisites..."

    if ! command -v docker &> /dev/null; then
        error "Docker is not installed."
        echo "Install Docker Desktop: https://docker.com/products/docker-desktop"
        echo "Or OrbStack: https://orbstack.dev"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        error "Docker is not running."
        echo "Please start Docker Desktop or OrbStack and try again."
        exit 1
    fi

    info "Docker is ready"
}

create_dockerfile() {
    info "Creating Dockerfile..."

    mkdir -p "$HOME/.claude/docker"

    cat > "$HOME/.claude/docker/Dockerfile.isolated" << 'EOF'
FROM node:22-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends git curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

USER node

ENV NPM_CONFIG_PREFIX=/home/node/.npm-global
ENV PATH="/home/node/.npm-global/bin:${PATH}"

RUN npm install -g @anthropic-ai/claude-code && npm cache clean --force

WORKDIR /workspace
ENTRYPOINT ["sh", "-c", "npm update -g @anthropic-ai/claude-code 2>/dev/null || true; exec claude"]
EOF

    info "Created ~/.claude/docker/Dockerfile.isolated"
}

build_image() {
    info "Building Docker image (this may take 1-2 minutes)..."

    if ! docker build \
        --tag claude-isolated \
        --file "$HOME/.claude/docker/Dockerfile.isolated" \
        "$HOME/.claude/docker/"; then
        error "Failed to build Docker image"
        exit 1
    fi

    info "Docker image built"
}

create_shell_functions() {
    info "Creating shell function files..."

    # Fish
    cat > "$HOME/.claude/claude-safe.fish" << 'EOF'
function claude-safe --description "Run Claude Code in an isolated Docker container"
    if not docker info >/dev/null 2>&1
        echo "Error: Docker is not running."
        return 1
    end

    set -l project (basename $PWD)
    set -l name "claude-safe-"(echo $project | tr -cd '[:alnum:]-_')
    docker rm -f $name 2>/dev/null

    # Ask for port
    read -P "Expose port for web server (enter to skip): " port

    set -l port_flag ""
    if test -n "$port"
        set port_flag "-p $port:$port"
    end

    echo ""
    echo "Starting isolated Claude environment..."
    echo "   Project: $project"
    if test -n "$port"
        echo "   Port: localhost:$port"
    end
    echo ""

    docker run -it --rm \
        --name $name \
        $port_flag \
        -v "$PWD:/workspace" \
        -v "$HOME/.claude:/home/node/.claude" \
        -w /workspace \
        --cap-drop=ALL \
        --security-opt no-new-privileges:true \
        claude-isolated
end

function claude-safe-build --description "Rebuild the Docker image"
    docker build --tag claude-isolated --file ~/.claude/docker/Dockerfile.isolated ~/.claude/docker/
end
EOF

    # Bash
    cat > "$HOME/.claude/claude-safe.bash" << 'EOF'
claude-safe() {
    if ! docker info >/dev/null 2>&1; then
        echo "Error: Docker is not running."
        return 1
    fi

    local project=$(basename "$PWD")
    local name="claude-safe-${project//[^a-zA-Z0-9_-]/}"
    docker rm -f "$name" 2>/dev/null

    # Ask for port
    read -p "Expose port for web server (enter to skip): " port

    local port_flag=""
    if [ -n "$port" ]; then
        port_flag="-p $port:$port"
    fi

    echo ""
    echo "Starting isolated Claude environment..."
    echo "   Project: $project"
    if [ -n "$port" ]; then
        echo "   Port: localhost:$port"
    fi
    echo ""

    docker run -it --rm \
        --name "$name" \
        $port_flag \
        -v "$PWD:/workspace" \
        -v "$HOME/.claude:/home/node/.claude" \
        -w /workspace \
        --cap-drop=ALL \
        --security-opt no-new-privileges:true \
        claude-isolated
}

claude-safe-build() {
    docker build --tag claude-isolated --file ~/.claude/docker/Dockerfile.isolated ~/.claude/docker/
}
EOF

    # Zsh
    cat > "$HOME/.claude/claude-safe.zsh" << 'EOF'
claude-safe() {
    if ! docker info >/dev/null 2>&1; then
        echo "Error: Docker is not running."
        return 1
    fi

    local project="${PWD:t}"
    local name="claude-safe-${project//[^a-zA-Z0-9_-]/}"
    docker rm -f "$name" 2>/dev/null

    # Ask for port
    read "port?Expose port for web server (enter to skip): "

    local port_flag=""
    if [[ -n "$port" ]]; then
        port_flag="-p $port:$port"
    fi

    echo ""
    echo "Starting isolated Claude environment..."
    echo "   Project: $project"
    if [[ -n "$port" ]]; then
        echo "   Port: localhost:$port"
    fi
    echo ""

    docker run -it --rm \
        --name "$name" \
        $port_flag \
        -v "$PWD:/workspace" \
        -v "$HOME/.claude:/home/node/.claude" \
        -w /workspace \
        --cap-drop=ALL \
        --security-opt no-new-privileges:true \
        claude-isolated
}

claude-safe-build() {
    docker build --tag claude-isolated --file ~/.claude/docker/Dockerfile.isolated ~/.claude/docker/
}
EOF

    info "Created shell functions at ~/.claude/"
}

print_instructions() {
    local shell_name
    shell_name=$(basename "$SHELL")

    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Installation complete${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo "Docker image: claude-isolated"
    echo "Shell functions: ~/.claude/claude-safe.{fish,bash,zsh}"
    echo ""
    echo -e "${YELLOW}Next step:${NC}"
    echo ""
    echo "1. Review the shell functions:"

    case "$shell_name" in
        fish)
            echo "   cat ~/.claude/claude-safe.fish"
            echo ""
            echo "2. If you trust it, add this line to ~/.config/fish/config.fish:"
            echo "   source ~/.claude/claude-safe.fish"
            ;;
        zsh)
            echo "   cat ~/.claude/claude-safe.zsh"
            echo ""
            echo "2. If you trust it, add this line to ~/.zshrc:"
            echo "   source ~/.claude/claude-safe.zsh"
            ;;
        *)
            echo "   cat ~/.claude/claude-safe.bash"
            echo ""
            echo "2. If you trust it, add this line to ~/.bashrc:"
            echo "   source ~/.claude/claude-safe.bash"
            ;;
    esac

    echo ""
    echo "3. Reload your shell, then:"
    echo "   cd ~/your-project"
    echo "   claude-safe"
    echo ""
}

main() {
    echo ""
    echo "claude-safe installer"
    echo "====================="
    echo ""

    check_prerequisites
    create_dockerfile
    build_image
    create_shell_functions
    print_instructions
}

main "$@"
