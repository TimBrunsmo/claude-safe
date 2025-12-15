# claude-safe

A shell command that runs Claude Code inside an isolated Docker container.

```bash
cd ~/my-project
claude-safe
```

That's it. Claude starts, but it can only see your project folder. Your SSH keys, cloud credentials, and other files are invisible and protected.

Develop in peace knowing that even if a malicious package gets installed, it's trapped inside the container and can't touch the rest of your system.

## Why?

When you run `npm install some-package`, that package can execute arbitrary code with your user's full permissions:

- Read your SSH keys (`~/.ssh`)
- Steal cloud credentials (`~/.aws`, `~/.config/gcloud`)
- Access browser data and cookies
- Read/modify any file your user can access

**This is not theoretical.** Supply chain attacks on npm packages happen regularly.

## How it works

`claude-safe` runs Claude inside a Docker container that can only access your current folder:

```
┌─────────────────────────────────────────┐
│           Your System (Host)            │
│                                         │
│  ~/.ssh ───────────── BLOCKED           │
│  ~/.aws ───────────── BLOCKED           │
│  ~/other-projects ─── BLOCKED           │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │     Docker Container            │    │
│  │                                 │    │
│  │  /workspace ← project folder    │    │
│  │                                 │    │
│  │  Claude Code runs here          │    │
│  │  npm install runs here          │    │
│  │  Malicious code is trapped      │    │
│  │                                 │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

## Install

### 1. Run the installer

```bash
curl -fsSL https://raw.githubusercontent.com/timbrunsmo/claude-safe/main/install.sh | bash
```

This builds the Docker image and creates shell functions at `~/.claude/`.

**The installer does NOT modify your shell config.** You do that yourself.

### 2. Review the shell functions

```bash
# Fish
cat ~/.claude/claude-safe.fish

# Bash
cat ~/.claude/claude-safe.bash

# Zsh
cat ~/.claude/claude-safe.zsh
```

### 3. Add to your shell config (if you trust it)

```bash
# Fish - add to ~/.config/fish/config.fish:
source ~/.claude/claude-safe.fish

# Bash - add to ~/.bashrc:
source ~/.claude/claude-safe.bash

# Zsh - add to ~/.zshrc:
source ~/.claude/claude-safe.zsh
```

### 4. Reload and use

```bash
cd ~/your-project
claude-safe
```

## Commands

| Command | Description |
|---------|-------------|
| `claude-safe` | Run Claude Code in an isolated Docker container |
| `claude-safe-build` | Rebuild the Docker image |

## Security Features

- **`--cap-drop=ALL`** - Removes all Linux capabilities
- **`--security-opt no-new-privileges:true`** - Prevents privilege escalation
- **Non-root user** - Runs as `developer` (UID 1000), not root
- **Minimal image** - Based on `node:22-slim`
- **Auto-cleanup** - Container removed on exit

### What's mounted

Only two directories:
1. **Your project folder** → `/workspace`
2. **Claude config** → `~/.claude` (for auth persistence)

Everything else is inaccessible.

### Verify isolation

Inside the container:

```bash
whoami              # → developer
ls /Users           # → No such file or directory
ls ~/.ssh           # → No SSH keys
env | grep -i aws   # → No credentials
```

## Requirements

- macOS or Linux
- [Docker Desktop](https://docker.com/products/docker-desktop) or [OrbStack](https://orbstack.dev)

## Uninstall

1. Remove the source line from your shell config
2. Remove files:
   ```bash
   rm -rf ~/.claude/docker ~/.claude/claude-safe.*
   docker rmi claude-isolated
   ```

## License

MIT
