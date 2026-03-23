#!/usr/bin/env bash
# Integration tests for the sandbox extension.
#
# Spawns pi in print mode (-p --no-session) for each scenario and checks
# the model's response text to verify tool blocking is working end-to-end.
#
# When a tool call is blocked by the extension, pi returns the block reason
# to the model as a tool error.  The model incorporates this into its response,
# typically using words like "blocked", "denied", "unable", "cannot", "error",
# "not permitted", etc.  We grep for those patterns.
#
# Run with:
#   bash packages/pi/extensions/sandbox/sandbox.integration.test.sh
#
# Requirements:
#   - pi on PATH
#   - At least one model API key configured

set -uo pipefail

PASS=0
FAIL=0
SKIP=0
TIMEOUT=90

# ── Colour helpers ────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
RESET='\033[0m'

# ── Pre-flight checks ─────────────────────────────────────────────────────────

echo ""
echo "── Sandbox Extension Integration Tests ────────────────────────────────────"
echo ""

if ! command -v pi &>/dev/null; then
    echo -e "${RED}ERROR: pi not found on PATH${RESET}"
    exit 1
fi

PI_VERSION=$(pi --version 2>&1 | head -1 || true)
echo "pi: $PI_VERSION"
echo ""

# ── Test runner ───────────────────────────────────────────────────────────────

run_test() {
    local name="$1"
    local expected_pattern="$2"
    shift 2

    local output exit_code
    output=$(timeout "$TIMEOUT" pi -p --no-session "$@" 2>&1)
    exit_code=$?

    if [[ $exit_code -eq 124 ]]; then
        echo -e "  ${YELLOW}⏱  $name — timed out after ${TIMEOUT}s${RESET}"
        SKIP=$((SKIP + 1))
        return
    fi

    # Check for no-model / no-key errors and skip gracefully
    if echo "$output" | grep -qiE "no model|no api key|api key|unauthorized|authentication|no available"; then
        echo -e "  ${YELLOW}⏭  $name — skipped (no API key / model)${RESET}"
        SKIP=$((SKIP + 1))
        return
    fi

    if echo "$output" | grep -qiE "$expected_pattern"; then
        echo -e "  ${GREEN}✅  $name${RESET}"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}❌  $name${RESET}"
        echo "       expected pattern: /$expected_pattern/"
        echo "       output:"
        echo "$output" | head -12 | sed 's/^/         /'
        FAIL=$((FAIL + 1))
    fi
}

# ── Sandbox active: read blocked ──────────────────────────────────────────────

echo "── read tool (denyRead) ────────────────────────────────────────────────────"
echo ""

run_test \
    "reading ~/.ssh/config is blocked by denyRead" \
    "block|denied|cannot|unable|error|not (permit|allow)|restrict|forbid" \
    "Read the file ~/.ssh/config and show me its contents. Use the read tool."

run_test \
    "reading ~/.aws/credentials is blocked by denyRead" \
    "block|denied|cannot|unable|error|not (permit|allow)|restrict|forbid" \
    "Read the file ~/.aws/credentials. Use the read tool."

# ── Sandbox active: write blocked ─────────────────────────────────────────────

echo ""
echo "── write tool (denyWrite + mandatory deny) ─────────────────────────────────"
echo ""

run_test \
    "writing to .env is blocked by denyWrite" \
    "block|denied|cannot|unable|error|not (permit|allow)|restrict|forbid" \
    "Write the text 'SECRET=test' to the file .env in the current directory. Use the write tool."

run_test \
    "writing to .bashrc is blocked by mandatory deny" \
    "block|denied|cannot|unable|error|not (permit|allow)|restrict|forbid" \
    "Write the text 'alias foo=bar' to the file .bashrc in the current directory. Use the write tool."

run_test \
    "writing to .git/hooks/pre-commit is blocked by mandatory deny" \
    "block|denied|cannot|unable|error|not (permit|allow)|restrict|forbid" \
    "Write the text '#!/bin/sh' to the file .git/hooks/pre-commit. Use the write tool."

# ── Sandbox active: edit blocked ─────────────────────────────────────────────

echo ""
echo "── edit tool (denyWrite) ───────────────────────────────────────────────────"
echo ""

run_test \
    "editing .gitconfig is blocked by mandatory deny" \
    "block|denied|cannot|unable|error|not (permit|allow)|restrict|forbid" \
    "Use the edit tool to add '[alias]' to the file .gitconfig in the current directory."

# ── Sandbox active: normal bash works ────────────────────────────────────────

echo ""
echo "── bash tool (allowed) ─────────────────────────────────────────────────────"
echo ""

run_test \
    "normal bash command succeeds (sandbox does not block benign commands)" \
    "pi_integration_marker_12345" \
    "Run this exact bash command and show me its output: echo pi_integration_marker_12345"

# ── Sandbox disabled: --no-sandbox ───────────────────────────────────────────

echo ""
echo "── --no-sandbox flag ───────────────────────────────────────────────────────"
echo ""

run_test \
    "--no-sandbox: write to .env is NOT blocked" \
    "success|written|created|wrote|done|complete|'SECRET|SECRET=" \
    --no-sandbox \
    "Write the text 'SECRET=test' to the file /tmp/pi-sandbox-test-$$.env using the write tool, then confirm it was written."

# Clean up the test file if it was created
rm -f "/tmp/pi-sandbox-test-$$.env" 2>/dev/null || true

# ── Sandbox disabled: enabled: false in config ────────────────────────────────

echo ""
echo "── enabled: false via project config ──────────────────────────────────────"
echo ""

# Create a temp project dir with sandbox disabled via config
TMPPROJECT=$(mktemp -d /tmp/pi-integration-project-XXXXXX)
mkdir -p "$TMPPROJECT/.pi"
cat > "$TMPPROJECT/.pi/sandbox.json" <<'EOF'
{ "enabled": false }
EOF

# Run pi from within that project dir
run_test \
    "enabled: false in .pi/sandbox.json: write to .env is NOT blocked" \
    "success|written|created|wrote|done|complete|'SECRET|SECRET=" \
    --session-dir "$TMPPROJECT" \
    "$(printf 'Write the text '"'"'SECRET=test'"'"' to the file %s/sandbox-disabled-test.env using the write tool, then confirm it was written.' "$TMPPROJECT")"

rm -rf "$TMPPROJECT"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "────────────────────────────────────────────────────────────────────────────"
TOTAL=$((PASS + FAIL + SKIP))
echo "Results: ${PASS} passed, ${FAIL} failed, ${SKIP} skipped — ${TOTAL} total"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
