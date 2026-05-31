# Sample sbx policies

These files document **the kinds of rules** you'd set with `sbx policy` for different scenarios. They're shown as commands you'd run, not as YAML / config files, because that matches the public CLI surface.

> ⚠️ **Validate exact CLI flags against your installed sbx version.** This labspace is built against the public docs at <https://docs.docker.com/ai/sandboxes/security/governance/> as of May 2026.

## balanced-dev.sh — Balanced developer policy

```bash
#!/usr/bin/env bash
# Balanced developer policy — enough open to be useful, enough closed to be safe.

# Network — AI providers
sbx policy allow network api.anthropic.com
sbx policy allow network api.openai.com

# Network — code hosts and registries
sbx policy allow network github.com
sbx policy allow network "*.github.com"
sbx policy allow network registry.npmjs.org
sbx policy allow network pypi.org
sbx policy allow network files.pythonhosted.org

# Network — explicit denies for common exfiltration channels
sbx policy deny network paste.ee
sbx policy deny network pastebin.com
sbx policy deny network hooks.slack.com
sbx policy deny network discord.com

# Filesystem — designated working areas
sbx policy allow filesystem "~/projects/**"        read-write
sbx policy allow filesystem "~/Documents/specs/**" read-only

# Filesystem — never let an agent see these
sbx policy deny filesystem "~/.ssh/**"
sbx policy deny filesystem "~/.aws/**"
sbx policy deny filesystem "~/.kube/**"
sbx policy deny filesystem "~/**/.env"
sbx policy deny filesystem "~/**/.env.*"
```

## restrictive.sh — Restrictive policy (for sensitive projects)

```bash
#!/usr/bin/env bash
# Restrictive policy — for sensitive projects (regulated, patent-track, OEM-confidential).

# Network — only Anthropic + internal services
sbx policy allow network api.anthropic.com
sbx policy allow network "*.bosch-internal.example"

# Filesystem — single project tree only
sbx policy allow filesystem "~/projects/sensitive-project/**" read-write

# Everything else: default deny
# (no need to write explicit denies — default is deny)
```

## research.sh — Research / R&D policy (broader, but patent-fenced)

```bash
#!/usr/bin/env bash
# Research / R&D policy — broader allowlist with hard patent-track fence.

# Network — research-relevant
sbx policy allow network api.anthropic.com
sbx policy allow network api.openai.com
sbx policy allow network "*.huggingface.co"
sbx policy allow network "*.kaggle.com"
sbx policy allow network "*.research-partner.example"

# Filesystem — research areas
sbx policy allow filesystem "~/research/public/**"   read-write
sbx policy allow filesystem "~/research/internal/**" read-write

# Filesystem — patent-track is hard-fenced
sbx policy deny filesystem "~/research/patent-track/**"
```

## Inspecting and resetting

```bash
sbx policy ls                  # List all active rules
sbx policy rm <rule-name>      # Remove a specific rule
sbx policy reset               # Wipe local rules; re-pull org policies
```

## A note on `**` vs `*`

Use `**` (double wildcard) for recursive matching. A single `*` matches only one path segment.

- `~/projects/*` matches `~/projects/foo` but NOT `~/projects/foo/src/main.c`.
- `~/projects/**` matches both.

The docs flag this explicitly in the troubleshooting section — if a mount unexpectedly fails with `mount policy denied`, this is the first thing to check.
