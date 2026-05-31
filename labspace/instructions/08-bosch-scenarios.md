# Section 08 — Bosch Scenarios: Per-Vertical Mapping

> 🎯 **Goal.** Translate the three pillars into concrete policies for Bosch's main verticals — Mobility, iBike, Manufacturing, R&D. This is the "what would this look like in *our* environment" lab.
>
> 👥 **Audience.** Everyone — but designed for the leadership / architect conversation that comes at the end of the workshop.
> ⏱ **~10 minutes.**
> 💬 **Discussion-led**, with example policy fragments to anchor it.

## How to use this lab

For each vertical below:

1. Read the scenario.
2. Look at the example policy fragments — these are illustrative, not prescriptive.
3. Discuss with the room: *"Which of these would actually apply to your team? What's missing? What's too restrictive?"*

The output of this discussion is what the follow-up workshops with each unit should focus on.

---

## Vertical 1 — Mobility

**Context.** Vehicle software, on-board AI assistants for engineers working on firmware, ECU code, and HMI. Highly regulated (UNECE WP.29, ISO 21434). Source code is sensitive; some IP is jointly developed with OEM partners.

**Scenarios where AI coding agents are useful:**

- Refactoring legacy C/C++ ECU firmware.
- Generating MISRA-compliant code patches.
- Reviewing diagnostic protocols (UDS, OBD-II) for spec adherence.
- Drafting test cases for HIL (Hardware-in-the-Loop) test benches.

**Risks the three pillars mitigate:**

- Agent leaks firmware IP to a public LLM endpoint.
- Agent reads OEM-partner-confidential design docs and posts to an internal Slack the partner can't see.
- Agent pulls a malicious MCP "vehicle-data" server from a random GitHub repo.

**Sample Sandbox Policy (network):**

```text
# Allow — approved AI providers and internal services
allow  api.anthropic.com
allow  api.openai.com
allow  *.bosch-internal.example
allow  github.bosch-internal.example
allow  *.bosch-mobility-partners.example

# Deny — known data-leak destinations and unsanctioned LLMs
deny   *.public-llm-experimental.example
deny   paste.ee
deny   hooks.slack.com
deny   pastebin.com
```

**Sample MCP catalog:**

- ✅ GitHub MCP (read-only tools allowed; write tools require senior approval)
- ✅ Internal "ECU-spec" MCP (Bosch-built, queries the spec database)
- ❌ Any community MCP server without security review

**Sample audit dashboards (for the security team):**

- Volume of denied calls per developer per week.
- Any access to OEM-partner repos by agents not on the partner's allowlist.

---

## Vertical 2 — iBike

**Context.** Embedded systems, motor control, battery management. Smaller team, faster iteration, but the agents have full filesystem access on the dev's machine which often includes early prototype designs.

**Scenarios:**

- Agent helps with motor-control firmware (rust, embedded C).
- Agent drafts battery-management state machines.
- Agent reads CAN bus traces to draft anomaly-detection logic.

**Risks the three pillars mitigate:**

- Prototype designs leak through agent's cloud LLM call.
- Agent pushes uncommitted code to a public GitHub fork by mistake.

**Sample Sandbox Policy (filesystem):**

```text
# Allow — designated working areas
allow  ~/projects/ibike-firmware/**     read-write
allow  ~/projects/ibike-battery/**      read-write
allow  ~/Documents/ibike-specs/**       read-only

# Deny — never let an agent see these
deny   ~/.ssh/**
deny   ~/.aws/**
deny   ~/**/.env
deny   ~/projects/oem-confidential/**
```

**Sample audit dashboards:**

- Any agent attempt to read paths outside the project tree.
- Push events to GitHub repos outside the `bosch-ibike-*` namespace.

---

## Vertical 3 — Manufacturing units

**Context.** Factory floor systems — PLCs, SCADA, MES integration. Engineers writing the IT side of OT systems. Network segmentation is the dominant security control today; AI agents complicate that picture because they originate from corporate IT but reach into OT.

**Scenarios:**

- Agent drafts integration code between MES and ERP.
- Agent helps debug PLC log parsers.
- Agent generates dashboard config for production-line OEE monitoring.

**Risks the three pillars mitigate:**

- Agent on a corporate laptop bridges IT and OT networks via misconfigured proxy.
- Agent pulls factory-floor logs (potentially containing recipe / process IP) and posts to a public LLM for analysis.

**Sample Sandbox Policy (network):**

```text
# Allow — approved AI providers and explicitly-scoped internal hosts
allow  api.anthropic.com
allow  api.openai.com
allow  mes.factory-network.bosch-internal.example
allow  erp.bosch-internal.example

# Deny — entire OT subnets unless explicitly scoped per-developer
deny   10.50.0.0/16     # OT segment — no agent should auto-reach this
deny   10.51.0.0/16     # OT segment
deny   *.public-llm-experimental.example
```

**Sample audit dashboards:**

- Any attempted IT→OT network call.
- Volume and identity of agents reaching MES/ERP endpoints.

---

## Vertical 4 — Bosch R&D

**Context.** Research org. Lots of experimentation. Lots of one-off projects. AI agents are heavily used. Lots of MCP server experimentation. Highest risk of "wild west" without governance.

**Scenarios:**

- Researchers spin up new agents weekly to try ideas.
- New MCP servers get tried out constantly.
- Patent-track research lives next to public-publishable research on the same disk.

**Risks the three pillars mitigate:**

- Patent-track findings leak into agent context that's later posted to a public LLM.
- Unsanctioned MCP servers become a back door.
- Nobody has a global picture of which research projects' code has touched which LLM endpoint.

**Sample Sandbox Policy (this team gets the most permissive baseline, but the audit volume is the highest):**

```text
# Network — relaxed but bounded
allow  api.anthropic.com
allow  api.openai.com
allow  *.research-partner.example
allow  *.huggingface.co
allow  *.kaggle.com

# Network — denied
deny   paste.ee
deny   *.unsanctioned-llm.example

# Filesystem — patent-track is hard-fenced
allow  ~/research/public/**             read-write
allow  ~/research/internal/**           read-write
deny   ~/research/patent-track/**     # No agent access, ever
```

**Sample MCP catalog:**

- Larger, but every server has a 90-day review cycle.
- Tools that write or post outside the sandbox require named approval.

**Sample audit dashboards:**

- Any agent reading anywhere under `patent-track/`.
- Top 10 most-used MCP tools per quarter.
- New MCP servers added to local catalogs (where delegation is on).

---

## How to drive the conversation in the room

After walking through these, ask the room three questions:

1. **What's missing?** Which scenarios *we didn't cover* are the highest-risk for your team?
2. **What's too tight?** Which of the example deny rules would block legitimate workflows?
3. **Who owns the policy?** Inside the BU, who would be the named owner — platform team? Security team? Engineering leadership?

The answer to (3) is the most important. It tells you who you're running the **next** workshop with.

---

## End of labspace

That's the full picture: the problem (Horror Stories), the three pillars in practice, the org-level model, and how each pillar maps to real Bosch work.

**For the leadership conversation,** the one-line takeaway is:

> *Same agent, same prompts, same code — different blast radius.*

That's what landed at DigiFusion. The labs above are how you turn it into actual workshops with each unit.

→ Back to **[README](../../README.md)**
