# Network Enforcement Demo

Define network policies in the Admin Console, watch them flow to your developer machine, and prove enforcement with three `curl` commands inside a sandbox.

This section proves the network half of Pillar 1. Section 04 proves the filesystem half.

**Time:** ~10 minutes
**Prerequisites:** You're an admin of `$$org$$` and you completed Section 00.

## What you'll prove

- Policies defined in `app.docker.com/admin/orgs/$$org$$` flow automatically to any developer logged in with org credentials
- An **allow** rule lets explicitly-permitted traffic through
- A **deny** rule blocks specific destinations
- The **default-deny posture** blocks anything not covered by an allow rule

## Step 1 — Open the Admin Console

Open **[app.docker.com/admin/orgs/$$org$$](https://app.docker.com/admin/orgs/$$org$$)** and navigate to **AI governance** → **Network access**.

Confirm the AI governance toggle is **ON**. If it isn't, turn it on.

## Step 2 — Set up the allow rules

If they're not already present, add two **Allow** rules.

**Rule 1: allow AI services**

- Action: Allow
- Network path (paste these as multiple lines — the modal accepts multi-line input):
  ```
  api.anthropic.com:443
  api.openai.com:443
  platform.claude.com:443
  *.googleapis.com:443
  statsig.anthropic.com:443
  ```
- Protocol: TCP, UDP
- Name: `allow AI services`

**Rule 2: allow Docker services**

- Action: Allow
- Network path:
  ```
  *.docker.com:443
  *.docker.io:443
  dhi.io:443
  ```
- Protocol: TCP, UDP
- Name: `allow Docker services`

## Step 3 — Add the deny rule

This is the rule that makes the demo land for security teams.

- Action: **Deny**
- Network path:
  ```
  paste.ee
  pastebin.com
  hooks.slack.com
  ```
- Protocol: TCP, UDP
- Name: `deny exfiltration`

## Step 4 — Remove any catch-all rule

If a rule exists with paths `0.0.0.0/0` or `::/0` (often labelled "allow all IPs"), **delete it**. Click the red trash icon on that row.

A catch-all `0.0.0.0/0` allow means everything is permitted regardless of other rules — the deny rule has nothing to prove. Removing it activates the default-deny posture.

After this, the final rule list should have exactly **three rules**:

- allow AI services (Allow)
- allow Docker services (Allow)
- deny exfiltration (Deny)

## Step 5 — Verify policies reached your machine

Back on your terminal:

```bash terminal-id=main
sbx policy reset
```

When prompted, choose **Balanced** (option 2).

Then list active policies:

```bash terminal-id=main
sbx policy ls
```

You should see:

- A header reading `Governance: managed by $$org$$`
- A fresh sync timestamp
- Three rules with `ORIGIN: remote` matching what you set in the Admin Console
- Several `default-*` rules marked `inactive — corporate policy takes precedence`

That last line is the central control proof. Even though sbx ships with sensible defaults, the org policy is overriding them.

## Step 6 — Spin up a sandbox

```bash terminal-id=main
mkdir -p ~/scratch && cd ~/scratch
sbx run shell .
```

This creates an isolated microVM with `shell` as the agent and the current directory as the workspace. Outbound network from the sandbox goes through the proxy that enforces your org policies.

You'll land at a shell prompt inside the sandbox.

## Step 7 — Run the three enforcement tests

Inside the sandbox prompt:

```bash terminal-id=main
curl -sS https://api.anthropic.com -o /dev/null -w "anthropic: %{http_code}\n"
curl -sS https://paste.ee -o /dev/null -w "paste.ee: %{http_code}\n"
curl -sS https://example.com -o /dev/null -w "example.com: %{http_code}\n"
```

## Step 8 — Read the results

Expected output (codes may vary slightly):

```
anthropic: 200
paste.ee: 403
example.com: 403
```

| Destination | Code | What it means |
| --- | --- | --- |
| `api.anthropic.com` | 200 or 404 | The connection reached Anthropic's servers. The point is the **sbx proxy let it through** because `allow AI services` covers it. |
| `paste.ee` | 403 | The **sbx proxy refused** the request. paste.ee never received the connection. Your `deny exfiltration` rule blocked it. |
| `example.com` | 403 | The **sbx proxy refused** the request. No allow rule covers it, so the default-deny posture catches it. |

The distinction between 200/404 (origin server replied) and 403 (proxy refused) is what proves enforcement happens at the policy layer, not at the destination.

## Step 9 — See the proxy refusal up close (optional)

For a more visceral demo, run a verbose `curl`:

```bash terminal-id=main
curl -v https://paste.ee 2>&1 | head -20
```

You'll see the proxy's `HTTP/1.1 403 Forbidden` response *before* any TLS handshake with paste.ee. The request never left your local network.

## Step 10 — Exit the sandbox

```bash terminal-id=main
exit
```

The microVM is torn down. Everything inside it is gone unless it was written to the mounted workspace.

## What you just demonstrated

The full Pillar 1 story end-to-end:

1. **One source of truth** — policies defined in the Admin Console for `$$org$$`
2. **Automatic propagation** — every developer logged in with org credentials inherits the policies
3. **Real enforcement** — the network proxy actually blocked the deny destination and the unscoped destination, while letting allowed traffic through
4. **No developer override** — local rules went inactive in favour of the org rules

Three rules, two browser tabs, three `curl`s — and you have a working enforcement story you can defend to a security team.

## Common questions

**"What if the developer just runs `docker logout`?"**
They can. But then they can't pull org-hosted images, push to org registries, or use any other org Docker services. The incentive is to stay logged in.

**"What if they run `sbx` without org credentials?"**
The local default policy (Balanced) applies — a generic dev allowlist. They lose access to anything outside that list *and* don't get the org-specific rules. They can do less, not more.

**"How fast does a policy change reach developers?"**
A few minutes typically. To force a refresh: `sbx policy reset`.

**"Can the developer override a deny rule locally?"**
No. Local rules are only honored for rule types the org policy does not own. Once the org defines network rules, local network rules go inactive.

Move on to Section 04 to prove the filesystem half of the same model.
