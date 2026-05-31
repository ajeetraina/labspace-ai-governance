#!/usr/bin/env bash
# balanced-dev.tmpl.sh — Balanced developer sbx policy.
# Run via: bash project/setup/render-org.sh project/policies/balanced-dev.tmpl.sh | bash
# Or render first:  bash project/setup/render-org.sh ... > rendered.sh

# Network — AI providers
sbx policy allow network api.anthropic.com
sbx policy allow network api.openai.com

# Network — code hosts and registries
sbx policy allow network github.com
sbx policy allow network "*.github.com"
sbx policy allow network registry.npmjs.org
sbx policy allow network pypi.org
sbx policy allow network files.pythonhosted.org

# Network — internal services (your org)
sbx policy allow network "*.{{INTERNAL_DOMAIN}}"
sbx policy allow network "github.{{INTERNAL_DOMAIN}}"

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
