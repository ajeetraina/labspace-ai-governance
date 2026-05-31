#!/usr/bin/env bash
# render-org.sh — Substitute org placeholders in any template file.
#
# Usage:
#   bash render-org.sh <template-file>
#   bash render-org.sh project/policies/balanced-dev.tmpl.sh
#
# Reads the .env produced by setup-org.sh and substitutes:
#   {{DOCKER_ORG}}       → e.g. bosch
#   {{INTERNAL_DOMAIN}}  → e.g. bosch-internal.example
#   {{EMAIL_DOMAIN}}     → e.g. bosch.example
#
# Output goes to stdout. To save:
#   bash render-org.sh tmpl.sh > rendered.sh

set -eu

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SETUP_DIR}/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found. Run setup-org.sh first." >&2
  exit 1
fi

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <template-file>" >&2
  exit 1
fi

TEMPLATE="$1"

if [[ ! -f "$TEMPLATE" ]]; then
  echo "ERROR: template file not found: $TEMPLATE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

# Apply substitutions
sed \
  -e "s|{{DOCKER_ORG}}|${DOCKER_ORG}|g" \
  -e "s|{{INTERNAL_DOMAIN}}|${INTERNAL_DOMAIN}|g" \
  -e "s|{{EMAIL_DOMAIN}}|${EMAIL_DOMAIN}|g" \
  "$TEMPLATE"
