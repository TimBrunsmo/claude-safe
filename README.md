# claude-safe

A shell command that runs Claude Code inside an isolated Docker container.

```bash
cd ~/my-project
claude-safe
```

That's it. Claude starts, but it can only see your project folder. Your SSH keys, cloud credentials, and other files are invisible and protected.

Develop in peace knowing that even if a malicious package gets installed, it's trapped inside the container and can't touch the rest of your system.

## Install

**One command:**

```bash
curl -fsSL https://raw.githubusercontent.com/timbrunsmo/claude-safe/main/install.sh | bash
```

This builds the Docker image and creates shell functions at `~/.claude/`.

**Make it permanent** (add ONE line to your shell config):

```bash
# Fish - add to ~/.config/fish/config.fish:
source ~/.claude/claude-safe.fish

# Bash - add to ~/.bashrc:
source ~/.claude/claude-safe.bash

# Zsh - add to ~/.zshrc:
source ~/.claude/claude-safe.zsh
```

Then reload your shell: `exec $SHELL` or open a new terminal.

> ⚠️ **Without adding the source line, you'll need to run `source ~/.claude/claude-safe.fish` every time you open a new shell**

**Optional:** Review the shell functions before adding them:
```bash
cat ~/.claude/claude-safe.fish  # or .bash or .zsh
```

## Usage

| Command | Description |
|---------|-------------|
| `claude-safe` | Run Claude Code in an isolated Docker container |
| `claude-safe-build` | Rebuild the Docker image |

```bash
cd ~/your-project
claude-safe
```

## Why?

When you run `npm install some-package`, that package can execute arbitrary code with your user's full permissions:

- Read your SSH keys (`~/.ssh`)
- Steal cloud credentials (`~/.aws`, `~/.config/gcloud`)
- Access browser data and cookies
- Read/modify any file your user can access

**This is not theoretical.** Supply chain attacks on npm packages happen regularly.

## How it works

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
│              ↑                          │
│         localhost:3000                  │
│     (only if you allow it)              │
└─────────────────────────────────────────┘
```

## Web Development

When you run `claude-safe`, it asks if you want to expose a port:

```
Expose port for web server (enter to skip): 3000
```

**If you enter a port:**
- Claude can start a dev server (Next.js, Vite, etc.)
- You access it in Chrome at `localhost:3000`
- This is the **only** way into the container

**If you press enter (skip):**
- No ports exposed
- Complete network isolation
- Use this when you don't need a web server

## Tips

### Passing arguments to Claude

You can pass any Claude CLI arguments through to the container:

```bash
# Skip permission prompts (faster, less safe)
claude-safe --dangerously-skip-permissions

# Start with a specific prompt
claude-safe --prompt "Fix all TypeScript errors"

# Combine multiple flags
claude-safe --dangerously-skip-permissions --prompt "Run tests"
```

Arguments are passed directly to the `claude` command inside the container.

## Security Details

- **`--cap-drop=ALL`** - Removes all Linux capabilities
- **`--security-opt no-new-privileges:true`** - Prevents privilege escalation
- **Non-root user** - Runs as `node` (UID 1000), not root
- **Minimal image** - Based on `node:22-slim`
- **Auto-cleanup** - Container removed on exit

### What's accessible

1. **Your project folder** → mounted at `/workspace`
2. **Claude config** → `~/.claude` (for auth persistence)
3. **One port** → only if you specify it at startup

Everything else on your system is inaccessible.

### Verify isolation

Inside the container:

```bash
whoami              # → node
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
