#!/usr/bin/env bash
# inventory.sh — Read-only inventory of what an unconstrained AI agent
# running as you could read or reach on this machine.
#
# This script does NOT exfiltrate, transmit, or modify anything.
# It only reports what would be reachable if it wanted to.
#
# Part of labspace-ai-governance Lab 1.

set -u

CLEANUP=0
if [[ "${1:-}" == "--cleanup" ]]; then
  CLEANUP=1
fi

if [[ $CLEANUP -eq 1 ]]; then
  echo "Nothing to clean — this script is read-only."
  exit 0
fi

echo "=== What an unconstrained agent could read ==="
echo

# SSH keys
if [[ -d "$HOME/.ssh" ]]; then
  echo "[FOUND] SSH keys in ~/.ssh/"
  for f in "$HOME/.ssh"/id_* "$HOME/.ssh/known_hosts" "$HOME/.ssh/config"; do
    if [[ -f "$f" && "$f" != *.pub ]]; then
      echo "  - $(basename "$f")"
    fi
  done
fi

# AWS creds
if [[ -f "$HOME/.aws/credentials" ]]; then
  echo "[FOUND] AWS credentials at ~/.aws/credentials"
fi

# kubeconfig
if [[ -f "$HOME/.kube/config" ]]; then
  echo "[FOUND] kubeconfig at ~/.kube/config"
fi

# GCP
if [[ -d "$HOME/.config/gcloud" ]]; then
  echo "[FOUND] gcloud config at ~/.config/gcloud/"
fi

# Azure
if [[ -d "$HOME/.azure" ]]; then
  echo "[FOUND] Azure config at ~/.azure/"
fi

# .env files in cwd and one level up
echo "[CHECKING] .env files near current directory..."
for d in "." ".." "$HOME"; do
  for env_file in "$d"/.env "$d"/.env.local "$d"/.env.production; do
    if [[ -f "$env_file" ]]; then
      echo "  - $env_file"
    fi
  done
done

# Git credentials
if [[ -f "$HOME/.git-credentials" ]]; then
  echo "[FOUND] Git credentials cached at ~/.git-credentials"
fi
if [[ -f "$HOME/.netrc" ]]; then
  echo "[FOUND] .netrc at ~/.netrc (often contains API tokens)"
fi

# Docker credentials
if [[ -f "$HOME/.docker/config.json" ]]; then
  echo "[FOUND] Docker config at ~/.docker/config.json (may contain registry tokens)"
fi

# Browser cookie DBs (just check for presence — never read)
for browser_path in \
  "$HOME/Library/Application Support/Google/Chrome/Default/Cookies" \
  "$HOME/.config/google-chrome/Default/Cookies" \
  "$HOME/Library/Application Support/Firefox/Profiles" \
  "$HOME/.mozilla/firefox"; do
  if [[ -e "$browser_path" ]]; then
    echo "[FOUND] Browser data at $browser_path"
    break
  fi
done

echo
echo "=== What an unconstrained agent could reach (network) ==="
echo
echo "Testing TCP connectivity to common endpoints..."

check_reach() {
  local host="$1"
  local port="${2:-443}"
  if timeout 2 bash -c "echo > /dev/tcp/$host/$port" 2>/dev/null; then
    echo "[REACHABLE] $host:$port"
  else
    echo "[BLOCKED]   $host:$port"
  fi
}

check_reach api.openai.com 443
check_reach api.anthropic.com 443
check_reach github.com 443
check_reach hooks.slack.com 443
check_reach paste.ee 443
check_reach discord.com 443
check_reach raw.githubusercontent.com 443
check_reach pastebin.com 443

echo
echo "=== End of inventory ==="
echo
echo "Everything marked [FOUND] is a secret an agent could read."
echo "Everything marked [REACHABLE] is somewhere data could be sent."
echo
echo "Next lab: applying Sandbox Policies to lock both down."
