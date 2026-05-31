# Section 05 — Org Governance Walkthrough

> 🎯 **Goal.** Understand how Sandbox Policies move from "every developer's local CLI" to "defined once in the Admin Console, enforced everywhere via the auth flow." This is the centralised governance story.
>
> 👥 **Audience.** Security leads, platform engineers, architects.
> ⏱ **~10 minutes.**
> 📸 **Screenshot-led walkthrough** (org governance requires the Docker Business + AI Governance Early Access subscription).
> 📸 **Screenshot-led** — org governance is Early Access on a paid subscription, so this section walks through screenshots of the Admin Console instead of running it live.

## Why this lab is a walkthrough, not hands-on

> 📌 Per the public docs: *"Sandbox organization governance is available on a separate paid subscription."* Most workshop attendees won't have an org with this enabled live. So we walk through it with annotated screenshots, then come back to your terminal to see what an end-developer experiences.
>
> If you do have an enabled org, every screen below is reproducible in your own Admin Console at <https://app.docker.com/admin>.

## The mental model

```
   ┌──────────────────────────────────────────────────────┐
   │  YOU (Org Admin)                                     │
   │  app.docker.com/admin → AI governance                │
   │  ─────────────────────────────────                   │
   │  • Network access rules   (allow / deny)             │
   │  • Filesystem rules        (allow / deny)            │
   │  • Delegation toggles     (User defined: on/off)     │
   └──────────────────┬───────────────────────────────────┘
                      │
                      │  Propagated through the auth flow
                      │  developers already use (Docker login)
                      ▼
   ┌──────────────────────────────────────────────────────┐
   │  EVERY DEVELOPER MACHINE                             │
   │  sbx daemon — pulls org policies on login            │
   │  • Local rules         → ORIGIN: local               │
   │  • Org rules           → ORIGIN: remote              │
   │  • Deny beats allow                                  │
   │  • Org beats local                                   │
   └──────────────────────────────────────────────────────┘
```

## Walkthrough — Step 1: Admin Console navigation

> 📸 **Screenshot.** `assets/screenshots/01-admin-console-nav.png`
>
> The Admin Console at `app.docker.com/admin` has a left navigation. Under the org, look for **AI governance settings**. Two sub-pages: **Network access** and **Filesystem access**.

## Walkthrough — Step 2: Define network rules

> 📸 **Screenshot.** `assets/screenshots/02-network-access-rules.png`

On the **Network access** page:

- Each rule has a **target** (domain, wildcard, or CIDR) and an **action** (allow / deny).
- Targets support:
  - Exact domains: `example.com`
  - Wildcard subdomains: `*.example.com` (does NOT match the root domain — add `example.com` too if you want both)
  - CIDR ranges: `10.0.0.0/8`
  - Optional port suffixes: `example.com:443`
- Multiple rules per textarea — one per line.

Example org-level network policy for an enterprise like Bosch:

```text
# Allow — AI providers and approved internal APIs
allow  api.anthropic.com
allow  api.openai.com
allow  *.bosch-internal.example
allow  github.com
allow  *.github.com
allow  registry.npmjs.org
allow  pypi.org
allow  files.pythonhosted.org

# Deny — known data-leak destinations and unsanctioned LLM endpoints
deny   paste.ee
deny   pastebin.com
deny   hooks.slack.com
deny   discord.com
deny   *.malicious-cdn.example
```

## Walkthrough — Step 3: Define filesystem rules

> 📸 **Screenshot.** `assets/screenshots/03-filesystem-access-rules.png`

On the **Filesystem access** page:

- Each rule has a **path pattern** and an **action** (allow / deny).
- **Use `**` (double wildcard) for recursive matching.** `*` only matches a single path segment — a common gotcha called out explicitly in the docs.

Example org-level filesystem policy:

```text
# Allow — designated working areas
allow  ~/projects/**         read-write
allow  ~/Documents/specs/**  read-only

# Deny — never let an agent see these
deny   ~/.ssh/**
deny   ~/.aws/**
deny   ~/.kube/**
deny   ~/.azure/**
deny   ~/.config/gcloud/**
deny   ~/**/.env
deny   ~/**/.env.*
deny   ~/.git-credentials
```

## Walkthrough — Step 4: The Delegation toggle

> 📸 **Screenshot.** `assets/screenshots/04-delegation-user-defined.png`

For each rule type, there's a **User defined** toggle:

- **Off (default):** Local rules of that type are *ignored*. Only the org policy is in effect.
- **On (delegated):** Local rules of that type are *evaluated alongside* org rules. Developers can add allow rules for additional domains the org hasn't explicitly denied.

> 🔒 **Org-level denials always win.** A delegated local allow can expand access only for domains the org hasn't denied. If the org denies `*.corp.internal`, a local allow for `build.corp.internal` has no effect.

> 🚫 **Blocked catch-alls.** When a rule type is delegated, local rules can't use ultra-broad patterns: `*`, `**`, `*.com`, `0.0.0.0/0`, `::/0` are rejected. Scoped wildcards like `*.example.com` are fine.

## Hands-on — Step 5: What the developer sees after org policies kick in

You can run this part for real even without an enabled org, since the CLI output below is documented public behaviour.

```bash
sbx policy ls
```

With an active org policy and one delegated rule type, the table looks like:

```text
NAME                  TYPE      ORIGIN   DECISION   STATUS                                                  RESOURCES
balanced-dev          network   local    allow      inactive — corporate policy takes precedence and does   api.anthropic.com
                                                    not delegate this rule type to local policy.
allow AI services     network   remote   allow      active                                                  api.anthropic.com
                                                                                                            api.openai.com
allow Docker services network   remote   allow      active                                                  *.docker.com
                                                                                                            *.docker.io
```

Two columns to notice:

- **ORIGIN** — `local` = this developer's machine, `remote` = pulled from the Admin Console.
- **STATUS** — `inactive` rules tell the developer their local rule isn't being honoured because the org hasn't delegated that rule type. Clear feedback, no silent override.

## Step 6 — Propagation timing

> 📌 Org policy changes take up to 5 minutes to propagate to developer machines. To force an immediate refresh:
>
> ```bash
> sbx policy reset
> ```
>
> ⚠️ This deletes all *local* rules. Org rules are re-pulled on the next `sbx` command.

## Step 7 — Recap

| Question | Answer |
|----------|--------|
| Where do org admins set policy? | Docker Admin Console → AI governance |
| How does it reach developers? | Through the auth flow they already use to sign into Docker |
| What enforces it? | The `sbx` daemon and the sandbox network proxy + mount layer |
| Can developers override deny rules? | No |
| Can developers add allow rules? | Only for rule types the admin has delegated (User defined: on) |
| How fast does a policy change propagate? | Up to 5 minutes (`sbx policy reset` to force) |

That's Pillar 1 end to end — local *and* organisational. The next two labs move to Pillar 2 (MCP) and Pillar 3 (Audit).

---

→ Next: **[Section 06 — Pillar 2: MCP Tool Governance](06-mcp-tool-governance.md)**
