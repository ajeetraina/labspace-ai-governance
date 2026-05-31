# Validation checklist

This labspace was built from the public Docker docs and AI Governance product page as of May 2026. Before running it live with Bosch or any other audience, **validate every CLI command and output against your installed `sbx` / `docker mcp` versions**. The list below is what to check, in priority order.

## Why this matters

Per your standard practice — "show, don't tell" — never publish or run a workshop with a command you haven't verified yourself. Docker Sandboxes and MCP Toolkit are both Early Access, so CLI surface, output format, and config paths may have shifted between this labspace's source-doc date (May 2026) and the workshop date.

## High priority — break the labs if wrong

### Lab 2 — Sandbox Policies (Local)

- [ ] `sbx --version` and `sbx status` work and look like the lab claims.
- [ ] `sbx run --agent docker-agent --workspace ./my-project` actually launches a sandbox with that flag syntax.
- [ ] `sbx policy ls` returns a table with the columns the lab describes: NAME, TYPE, ORIGIN, DECISION, STATUS, RESOURCES.
- [ ] Default-allow rules exist for AI providers (`api.anthropic.com`, `api.openai.com`), package managers (`registry.npmjs.org`, `pypi.org`), and code hosts (`github.com`). Confirm exact rule names.
- [ ] `sbx policy allow network <host>` and `sbx policy deny network <host>` work and reflect in `sbx policy ls`.
- [ ] `sbx policy allow filesystem "<path>/**" read-write` works with the read-write/read-only modifier.
- [ ] `sbx policy reset` exists and prompts for confirmation before wiping local rules.
- [ ] Trying to mount a denied path actually fails with `mount policy denied` (or similar) at sandbox start.

### Lab 3 — Blast Radius

- [ ] `sbx shell` exists and opens a shell inside a running sandbox.
- [ ] Network calls to denied hosts inside the sandbox fail at the proxy (not at DNS, not at TCP — confirm the failure mode message).
- [ ] Filesystem paths not mounted are truly invisible (not just permission-denied).

### Lab 5 — MCP Tool Governance

- [ ] `docker mcp ls` and `docker mcp catalog ls` exist with these names.
- [ ] `docker mcp enable <server>` works for at least one server (GitHub is the safest bet — confirm it's in the public catalog).
- [ ] `docker mcp logs --follow` shows live tool calls with decision + reason.
- [ ] `sbx run` accepts a `--mcp <server>` flag (or however MCP attachment is currently spelled — could be `--mcp-server`, `--with-mcp`, etc.).

### Lab 6 — Audit & Visibility

- [ ] An audit CLI command actually exists. Likely names: `sbx audit ls`, `sbx audit export`, `sbx events ls`. **This is the part I'm least sure about — confirm the exact subcommand and update the lab text.**
- [ ] The structured event format I used (event_id, timestamp, user, session, policy, request, decision, reason) roughly matches what `sbx` actually emits. If field names differ, regenerate `sample-events.jsonl` from real output.
- [ ] `view-events.sh` runs against real event output (it's just `jq`, but field names matter).

## Medium priority — cosmetic but visible

- [ ] CLI prompts shown in the labs (`$`, `>`, etc.) match what your sbx actually prints.
- [ ] Error messages quoted in the labs match the real wording. The docs page quotes `inactive — corporate policy takes precedence and does not delegate this rule type to local policy` — confirm exact spelling/punctuation.
- [ ] Default allowlist rule names (`default-ai-providers`, `default-package-mgrs`, etc.) — these are my best guesses from context. Replace with the actual names you see when you run `sbx policy ls` on a fresh install.

## Lower priority — content polish

- [ ] Bosch vertical examples in Lab 7 align with how Ramesh / the Bosch team would actually frame each unit's risk posture. Worth a quick read-through with him.
- [ ] Network rule examples in Lab 7 reference reasonable-sounding internal domains (`bosch-internal.example`) — swap with whatever fictional placeholders Bosch is comfortable with for a labspace that may end up on GitHub.

## What I couldn't validate from this environment

- I couldn't run sbx in this build environment (no Docker Desktop, no Linux sbx binary).
- I couldn't confirm the exact `sbx audit` subcommand surface.
- I couldn't confirm the MCP gateway log format.
- I couldn't capture the Admin Console screenshots (no enabled org).

Each of these has a "validate before running" callout in the corresponding lab so the gap is visible to a future reader / runner, not hidden.

## Suggested validation flow

1. On a clean Docker Desktop install, run through Labs 1–3 end to end. Note any command that doesn't behave like the lab says it should.
2. For Lab 4, capture the five Admin Console screenshots from a Business org with AI Governance enabled (or use the fallback in `assets/screenshots/README.md`).
3. For Lab 5, run through Docker MCP Toolkit + Gateway in your environment. Update the lab if the CLI shape has moved.
4. For Lab 6, this is the most uncertain — run real events through and update the lab to match.
5. For Lab 7, no validation needed; it's discussion-driven.
