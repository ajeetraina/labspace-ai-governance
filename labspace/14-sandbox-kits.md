# Sandbox Kits - Governance as Code

The last three sections were the **admin's** view: network, filesystem, and MCP policies authored in Docker Hub and enforced on every sandbox in `$$org$$`. This section is the **developer's** view - how you package a sandbox that's reproducible and compliant *by construction*, instead of a pile of `sbx run` flags and a setup doc.

The answer is a **kit**: a declarative artifact - a `spec.yaml` plus an optional `files/` directory - that bundles everything a sandbox needs: tools to install, files to inject, network rules, credential wiring, and the agent itself.

**Time:** ~10 minutes
**Prerequisites:** Sections 03, 04, and 06.

## Why kits matter for governance

You already met every property a kit packages - kits just make them **declarative, composable, and shareable**:

| Property | You saw it in | A kit makes it... |
| --- | --- | --- |
| Egress allowlist | Network (03) | a few lines of `network.allowedDomains` in `spec.yaml` |
| Credentials never enter the VM | Credential Isolation (12) | `credentials.sources` + proxy `serviceAuth`, wired once |
| One governed MCP endpoint | MCP (06) | servers declared in the kit, attached at creation |
| Reproducible workspace | Filesystem (04) | static `files/` injected into the workspace |

Instead of "clone this, export that, remember `--kit` twice," a teammate runs **one command** and gets your exact, governed setup.

## Two kinds of kits

**Mixin kits** (`kind: mixin`) extend an existing agent - add a tool, drop in config, grant a new service. Stack several with multiple `--kit` flags.

**Agent kits** (`kind: agent`) define a full agent from scratch - image, entrypoint, network, credentials. The built-in `claude` you've been using is itself an agent kit; you can fork it and change one thing.

## What a kit can declare

| Field | What it does |
| --- | --- |
| `commands.install` | Runs once at creation - installs tools |
| `commands.startup` | Runs on every start - background services |
| `files/` | Static files injected into `/home/agent/` or the workspace |
| `network.allowedDomains` | Domains the sandbox may reach |
| `credentials.sources` | Where the proxy reads secrets on the host (never in the VM) |
| `environment.proxyManaged` | Env vars whose values the proxy injects per request |

## A minimal mixin - build it step by step

A kit can be as small as a spec plus one file. This mixin ships a Claude Code skill into the workspace - no install step, just file injection. You'll end up with:

```
kits/docker-review/
├── spec.yaml
└── files/workspace/.claude/skills/docker-review/SKILL.md
```

### Step 1 - Create the kit layout

Work under `~/workdemo` so the sandbox mount stays inside the filesystem path your org policy allows (Section 04):

```bash no-run-button
mkdir -p ~/workdemo/kits-lab/kits/docker-review/files/workspace/.claude/skills/docker-review
cd ~/workdemo/kits-lab
```

### Step 2 - Write the kit spec

```bash no-run-button
cat > kits/docker-review/spec.yaml <<'EOF'
schemaVersion: "1"
kind: mixin
name: docker-review
displayName: Dockerfile review skill
description: Ships a Claude Code skill that reviews Dockerfiles
EOF
```

That's the entire spec - no network rules, no install commands, just the skill file the `files/` tree injects.

### Step 3 - Write the skill file

```bash no-run-button
cat > kits/docker-review/files/workspace/.claude/skills/docker-review/SKILL.md <<'EOF'
---
name: docker-review
description: Review a Dockerfile for best practices. Use when the user asks to review, audit, or improve a Dockerfile.
---

When reviewing a Dockerfile, check:

1. **Base image** - pinned tag or digest, minimal for the workload
2. **Layer order** - dependencies before app source to maximise cache reuse
3. **Image size** - multi-stage builds, `.dockerignore`, `--no-cache` / `--no-install-recommends`
4. **Security** - non-root `USER`, no secrets in `ARG`/`ENV`, no `--privileged`
5. **Reproducibility** - pinned package versions, explicit `COPY` targets
EOF
```

### Step 4 - Validate the spec (optional, catches errors early)

```bash no-run-button
sbx kit validate ./kits/docker-review/
```

### Step 5 - Run it, stacked on the built-in agent

```bash no-run-button
sbx run claude --kit ./kits/docker-review/ --name kits-lab
```

Once Claude loads, ask it:

```
Review the Dockerfile in this workspace
```

The `files/workspace/` tree lands in the workspace at creation, and Claude Code discovers the skill at `.claude/skills/docker-review/SKILL.md` automatically. Nothing is installed, no shell commands run - the kit is entirely file-based.

## Layer kits like the enterprise pattern

Kits compose, so real deployments split concerns across layers and stack them (illustrative layer names):

```bash no-run-button
sbx run claude \
  --kit ./kits/enterprise-base/   \  # egress allowlist + credential wiring
  --kit ./kits/node-python/       \  # language toolchains
  --kit ./kits/enterprise-cfg/       # .gitconfig, .npmrc, settings.json
```

Swap the language layer without touching the security layer. `allowedDomains` are unioned, `files/` from every kit are injected, and install commands run in order.

## The governance ceiling: kits don't widen policy

This is the point that ties kits back to the last three sections. A kit's `network.allowedDomains` are **additive on top of what's already allowed** - but when `$$org$$` owns a rule type, **org policy is the ceiling**. A domain your kit lists that the org policy doesn't allow stays **blocked** (default-deny; local rules go inactive because *corporate policy takes precedence* - Section 02).

> [!IMPORTANT]
> Kits are developer-side convenience; **org governance is authoritative.** A kit can make an *approved* setup reproducible - it cannot grant an agent access the CISO's policy denies. Network, filesystem, and MCP policy all still win. That's the whole point: developers move fast *inside* the guardrails.

## How kits map to the three pillars

| Pillar | Enforced by (admin) | Packaged by (kit) |
| --- | --- | --- |
| Network | Org network policy | `network.allowedDomains` (within the org ceiling) |
| Credential | Proxy injection | `credentials.sources` + `serviceAuth` |
| MCP | Cedar allow-list at the gateway | servers declared / attached by the kit |
| Filesystem | Org filesystem policy | `files/` workspace injection (within allowed paths) |

## Go deeper

The hands-on kit-authoring track - build a mixin, wire proxy-managed credentials, fork an agent, stack and share via Git/OCI:

- **[docs.docker.com/ai/sandboxes/customize/kits](https://docs.docker.com/ai/sandboxes/customize/kits/)** - the full spec reference
- **[github.com/docker/sbx-kits-contrib](https://github.com/docker/sbx-kits-contrib)** - the official community kits repo

With policies enforced by the org and kits packaging compliant setups for developers, you've seen both sides of the model. Next, **Putting It All Together** runs one rogue agent against all of it at once.
