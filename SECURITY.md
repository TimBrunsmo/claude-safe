# Security Policy

## Purpose

claude-safe is designed to protect your system from supply chain attacks by running Claude Code in isolated Docker containers. Security is our primary concern.

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in claude-safe, please report it responsibly:

1. **Do not** open a public GitHub issue for security vulnerabilities
2. Email the maintainer directly with:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Any suggested fixes

## Security Model

### What claude-safe protects against

- Malicious npm packages accessing your SSH keys
- Supply chain attacks stealing cloud credentials
- Compromised dependencies reading sensitive files outside the project
- Privilege escalation from within the container

### What claude-safe does NOT protect against

- Vulnerabilities in the Claude Code application itself
- Network-based attacks if the container has network access
- Malicious code that only affects the current project directory
- Docker engine vulnerabilities
- Kernel exploits (containers share the host kernel)

### Security measures implemented

1. **`--cap-drop=ALL`** - Removes all Linux capabilities
2. **`--security-opt no-new-privileges:true`** - Prevents gaining additional privileges
3. **Non-root user** - Container runs as UID 1000, not root
4. **Minimal base image** - Uses `node:22-slim` to reduce attack surface
5. **Limited mounts** - Only project directory and Claude config are accessible

## Best Practices

When using claude-safe:

1. Always use `claude-safe` instead of running Claude Code directly
2. Review the container output for suspicious activity
3. Keep Docker updated to the latest version
4. Consider using network isolation (`--network none`) for highly sensitive projects
5. Regularly rebuild the image with `claude-safe-build` to get security updates

## Audit

The install script and Dockerfile are intentionally kept simple and readable for security auditing. We encourage users to review the code before running it.
