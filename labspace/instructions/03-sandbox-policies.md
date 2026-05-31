# Section 03 — Pillar 1: Sandbox Policies (Local)

> 🎯 **Goal.** Move the agent off your host and into a Docker Sandbox. Apply local network and filesystem policies with `sbx policy`. Watch the same horror-story behaviour get blocked.
>
> 👥 **Audience.** Developers, architects.
> ⏱ **~15 minutes.**

> ⚠️ **Validate before running.** Docker Sandboxes is Early Access. Re-check exact CLI flags against your installed `sbx` version (`sbx --version`) before running these commands live. Anything that doesn't match — flag it and we'll fix the lab.

## Step 1 — Verify your sandbox setup

```bash
sbx --version
sbx status
```

If `sbx` isn't installed: on macOS / Windows it ships with Docker Desktop ≥ 4.45 as `docker sandbox`. On Linux/CI you install the standalone `sbx` binary. Same engine, two names.

## Step 2 — Start an agent inside a sandbox

We'll run a Docker Agent inside a sandbox so you can see the default boundaries. Pick any agent supported by sbx — Claude Code, Codex, Copilot, Gemini, Docker Agent. For the lab we'll use Docker Agent because it's the most portable.

```bash
sbx run --agent docker-agent --workspace ./my-project
```

This:

- Spins up a microVM (hard hypervisor boundary).
- Mounts only `./my-project` as the agent's workspace.
- Routes all the agent's network calls through the sbx network proxy.
- Applies the **default deny** posture for outbound traffic.

## Step 3 — Inspect the default policy

In a second terminal, list the active policy:

```bash
sbx policy ls
```

You should see something like:

```text
NAME                  TYPE      ORIGIN    DECISION   STATUS    RESOURCES
default-ai-providers  network   default   allow      active    api.anthropic.com
                                                                api.openai.com
                                                                api.x.ai
default-package-mgrs  network   default   allow      active    registry.npmjs.org
                                                                pypi.org
                                                                files.pythonhosted.org
default-source        network   default   allow      active    github.com
                                                                *.github.com
                                                                gitlab.com
```

> 📌 **What you're looking at.** The default sandbox isn't wide-open. It ships with a curated allowlist of AI providers, package registries, and code-hosting domains — the things a coding agent legitimately needs. Everything else is denied by default.

## Step 4 — Watch a deny in action

From inside the agent, ask it to reach somewhere outside the allowlist. The simplest way is to drop into a sandbox shell and try directly:

```bash
sbx shell
# Inside the sandbox:
curl -v https://paste.ee
curl -v https://hooks.slack.com
exit
```

Both calls should fail at the network-proxy layer with a policy-denied error, not a network error. **The agent doesn't even reach the destination's DNS resolution.** That's enforcement, not advice.

## Step 5 — Add a local allow rule

Suppose your team genuinely needs the agent to reach an internal API. Allow it locally:

```bash
sbx policy allow network api.bosch-internal.example
```

List again:

```bash
sbx policy ls
```

You'll see your new local rule with `ORIGIN: local`. From inside the sandbox, `curl https://api.bosch-internal.example` will now succeed (assuming the host is reachable).

## Step 6 — Add a local deny rule

Sometimes you want to explicitly block a domain. Deny rules beat allow rules:

```bash
sbx policy deny network *.suspicious-cdn.example
```

Try it from the sandbox — denied even if a wildcard allow exists.

## Step 7 — Filesystem mount rules

By default, sandboxes can mount any directory the user has access to. Tighten this for the lab:

```bash
sbx policy allow filesystem "~/projects/**" read-write
sbx policy allow filesystem "~/Documents/specs/**" read-only
sbx policy deny  filesystem "~/.ssh/**"
sbx policy deny  filesystem "~/.aws/**"
sbx policy deny  filesystem "~/**/.env"
```

> 📌 **Note the `**`.** Use `**` (double wildcard) — `*` only matches a single path segment. `~/*` matches files in `~/`; `~/**` matches everything under `~/`. The docs flag this explicitly under the troubleshooting section.

Try to launch a sandbox that mounts `~/.ssh` — the daemon rejects the mount before the agent starts:

```bash
sbx run --agent docker-agent --workspace ~/.ssh
# Expected: mount policy denied
```

## Step 8 — Inspect and clean up

```bash
sbx policy ls
sbx policy rm <rule-name>
```

To wipe local policy entirely:

```bash
sbx policy reset
```

> ⚠️ `sbx policy reset` deletes every local rule and re-pulls org policies. Prompts for confirmation. Don't run this on a real machine without thinking.

---

## Recap

You moved the agent into a sandbox, saw the default-deny posture, added local allow and deny rules for both network and filesystem, and watched both layers enforce.

But this is all **local** — every developer manages their own list. Next lab is the Blast Radius Test, then we'll see how an org enforces this centrally.

→ Next: **[Section 04 — Blast Radius Test](04-blast-radius.md)**
