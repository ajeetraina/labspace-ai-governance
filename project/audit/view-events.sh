#!/usr/bin/env bash
# view-events.sh — A jq-based viewer that simulates what a SIEM dashboard
# would do with the structured event stream emitted by Docker AI Governance.
#
# Usage:
#   cat events.jsonl | bash view-events.sh
#
# Part of labspace-ai-governance Lab 6.

set -eu

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required. Install it (apt install jq / brew install jq) and retry."
  exit 1
fi

# Read all events into a temp file so we can scan it multiple times.
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
cat > "$TMP"

if [[ ! -s "$TMP" ]]; then
  echo "No events on stdin. Pipe events.jsonl into this script."
  exit 1
fi

TOTAL=$(wc -l < "$TMP" | tr -d ' ')
ALLOWED=$(jq -c 'select(.decision == "allow")' "$TMP" | wc -l | tr -d ' ')
DENIED=$(jq -c 'select(.decision == "deny")'  "$TMP" | wc -l | tr -d ' ')

# Avoid division by zero
if [[ "$TOTAL" -eq 0 ]]; then
  PCT_ALLOWED=0
  PCT_DENIED=0
else
  PCT_ALLOWED=$(( ALLOWED * 100 / TOTAL ))
  PCT_DENIED=$(( DENIED  * 100 / TOTAL ))
fi

cat <<EOF
=== Audit summary ===

Total events:        $TOTAL
  allowed:           $ALLOWED (${PCT_ALLOWED}%)
  denied:            $DENIED (${PCT_DENIED}%)

By user:
EOF
jq -r '.user.email' "$TMP" | sort | uniq -c | sort -rn | awk '{printf "  %-40s %s\n", $2, $1}'

echo
echo "By rule:"
jq -r '"\(.policy.rule_name) (\(.decision))"' "$TMP" \
  | sort | uniq -c | sort -rn \
  | awk '{count=$1; $1=""; printf "  %-40s %s\n", substr($0,2), count}'

echo
echo "Top denied targets:"
jq -r 'select(.decision == "deny") | .request.target' "$TMP" \
  | sort | uniq -c | sort -rn | head -10 \
  | awk '{printf "  %-40s %s\n", $2, $1}'

echo
echo "By rule origin:"
jq -r '.policy.rule_origin' "$TMP" | sort | uniq -c | sort -rn | awk '{printf "  %-40s %s\n", $2, $1}'

echo
echo "Anomaly check:"
# Flag users with >= 5 denies in this window
jq -r 'select(.decision == "deny") | .user.email' "$TMP" \
  | sort | uniq -c | sort -rn \
  | awk '$1 >= 5 {printf "  ⚠ user %s triggered %s denies — investigate.\n", $2, $1}'

echo
echo "Tip: pipe the same JSONL to your real SIEM forwarder for production use."
