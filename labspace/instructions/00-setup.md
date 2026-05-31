# Setup — Tell us about your org

> 🎯 **Goal.** Personalise the labspace to your Docker org so policy examples reference *your* domains instead of generic placeholders.
>
> ⏱ **~2 minutes.**
>


## Why this step

Throughout the labs we'll show network policies, audit events, and Bosch-style scenarios that reference internal domains. Rather than hardcoding `acme-corp-internal.example` everywhere, the labspace lets you set your real (or pretend) org name once. Substitutes through.

## Step 1 — Run the setup script

In the terminal panel (right side), run:

```bash
bash ./project/setup/setup-org.sh
```

You'll be prompted for two things:

1. **Your Docker org name** — e.g. `bosch`, `acme-corp`, `mycompany`. Lowercase, hyphens OK. This becomes `DOCKER_ORG`.
2. **Your email domain** — e.g. `bosch.example`. Used in sample audit events.

If you just press Enter, defaults are `acme-corp` and `acme-corp.example`.

> 💡 **For workshops:** if you're running this as a facilitator with a specific customer, type their org name (e.g. `bosch`). The lab text will read naturally to that audience.

## Step 2 — Verify the values are saved

```bash
cat ./project/setup/.env
```

You should see something like:

```text
DOCKER_ORG="bosch"
INTERNAL_DOMAIN="bosch-internal.example"
EMAIL_DOMAIN="bosch.example"
```

## Step 3 — Try rendering a policy template

To see substitution in action, render one of the example policies:

```bash
bash ./project/setup/render-org.sh ./project/policies/balanced-dev.tmpl.sh
```

You should see the policy with your org's domain inserted, e.g. `sbx policy allow network "*.bosch-internal.example"`.

## You can re-run any time

If you want to change the org name (different customer, different demo), just run `setup-org.sh` again. It overwrites `.env`.

---

→ Next: **[Section 01 — Introduction: The Three Pillars](01-introduction.md)**
