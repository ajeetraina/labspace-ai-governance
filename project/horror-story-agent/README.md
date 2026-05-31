# Horror Story Agent

A **read-only inventory script** that demonstrates what an AI coding agent with default permissions on a developer's machine could access — without actually exfiltrating or transmitting anything.

Used in **Lab 1**.

## What it does

- Lists which secret stores exist on the machine (SSH keys, AWS creds, kubeconfig, .env files, browser cookies, git credentials, etc.) — **never reads their contents**.
- Tests TCP reachability to common exfiltration destinations (Slack webhooks, Discord, pastebin, GitHub) — **never sends data**.

## What it does NOT do

- ❌ Does not read the contents of any credential file.
- ❌ Does not transmit any data anywhere.
- ❌ Does not modify any file.

You can audit it: it's ~80 lines of bash. Read it before running it.

## Why it's safe to run in a workshop

Everything is `[[ -f "$file" ]]` checks (existence only) and `bash -c "echo > /dev/tcp/host/port"` connectivity probes. There are no `cat`, `curl`, `wget`, or `scp` calls anywhere.

## Run

```bash
bash inventory.sh
```

## Run cleanup

```bash
bash inventory.sh --cleanup
```

(The script writes nothing, so cleanup is a no-op — but the flag is there for parity with destructive demo scripts.)
