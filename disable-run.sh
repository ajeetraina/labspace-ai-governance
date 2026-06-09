#!/bin/bash
# disable-run.sh
#
# Adds the `no-run-button` flag to every runnable code block in the labspace
# markdown so the interface renders Copy-only (the Run button is hidden, the
# Copy button is kept).
#
# How the labspace interface actually works (verified against the interface
# bundle): it splits the fence info-string on whitespace and hides the Run
# button when one of the tokens is exactly `no-run-button`. The token MUST be
# whitespace-delimited — gluing it onto the language or the command breaks
# parsing and the block renders as "undefined".
#
# This script therefore handles two cases:
#   ```bash                  -> ```bash no-run-button
#   ```bash terminal-id=main -> ```bash no-run-button   (terminal-id is a
#                                                         no-op in this
#                                                         interface)
# and is idempotent: blocks that already carry `no-run-button` are left alone.
#
# It uses \h (horizontal whitespace) rather than \s so the trailing newline is
# never consumed — that newline bug is what previously merged the command onto
# the fence line.

set -e

BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RESET='\033[0m'
log()  { echo -e "${CYAN}==>${RESET} ${BOLD}$1${RESET}"; }
ok()   { echo -e "  ${GREEN}✓${RESET} $1"; }
warn() { echo -e "  ${YELLOW}!${RESET} $1"; }

if [ ! -d "labspace" ]; then
  echo "ERROR: Run this script from the root of your labspace clone."
  exit 1
fi

log "Adding no-run-button to all bash/sh/console code blocks..."

# Matches a fence opener whose language is bash/sh/console, optionally followed
# by attributes (e.g. terminal-id=main), but NOT already carrying
# no-run-button. Captures the language in $1. \h* = horizontal whitespace only
# (never the newline). Any existing attributes are dropped in favour of
# no-run-button.
pattern='s/^```(bash|sh|console)\h+(?!.*\bno-run-button\b).*$/```$1 no-run-button/; s/^```(bash|sh|console)\h*$/```$1 no-run-button/'

for f in labspace/*.md; do
  [ -f "$f" ] || continue

  before=$(grep -cE '^```(bash|sh|console)( |$)' "$f" 2>/dev/null || echo 0)
  already=$(grep -cE '^```(bash|sh|console) no-run-button( |$)' "$f" 2>/dev/null || echo 0)
  todo=$(( before - already ))

  if [ "$todo" -le 0 ]; then
    ok "$f — nothing to patch ($already already done)"
    continue
  fi

  perl -i -pe "$pattern" "$f"

  # Safety net: a correctly-patched block has the command on the NEXT line, so
  # the fence line must never have content glued after no-run-button.
  if grep -qnE '^```(bash|sh|console) no-run-button.+' "$f"; then
    warn "$f — detected a merged fence line; this is a bug, please review"
  fi

  ok "$f — patched $todo block(s)"
done

log "Done! Staging changes..."

git add labspace/*.md
git diff --cached --stat

read -p "Commit and push? (y/n) " confirm
if [[ "$confirm" == "y" ]]; then
  git commit -m "fix: disable Run button on all code blocks, keep Copy only"
  git push origin "$(git rev-parse --abbrev-ref HEAD)"
  echo -e "\n${GREEN}✓ Pushed${RESET}"
else
  echo "Changes staged but not committed. Run 'git commit' when ready."
fi
