#!/usr/bin/env bash
# push-my-branch.sh — run the "share-local-to-branch.yml" workflow
# Usage: ./push-my-branch.sh <branch> [commit message]

set -euo pipefail

# Resolve script + project roots (script is expected to live in bin/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source reusable helpers (logging, env loader, repo derivation, runner ensure)
# shellcheck source=/dev/null
. "$PROJECT_ROOT/lib/action_helpers.sh"

# --- Config / Args ---
WORKFLOW_FILE=".github/workflows/share-local-to-branch.yml"
BRANCH="${1:-}"
COMMIT_MESSAGE="${2:-"chore: share local work → branch"}"

# Runner-related defaults (can be overridden via env before running)
: "${RUNNER_OWNER:=Bridge-Placement}"
: "${RUNNER_START_TIMEOUT_SEC:=180}"
: "${RUNNER_LOG_POLL_INTERVAL:=5}"
: "${RUNNER_SETUP_SCRIPT_REL:=etc/setup-github-runner.sh}"
# Default readiness patterns (only set if not already provided)
if [[ -z "${RUNNER_READY_PATTERNS_SET:-}" ]]; then
  # Generic patterns (regex: prefix enables regex matching in helper) so any job name/result qualifies.
  declare -a RUNNER_READY_PATTERNS=(
    "Listening for Jobs" \
    "Runner reconnected" \
    "regex:Job .* completed with result: (Succeeded|Failed|Cancelled)" \
    "regex:completed with result: (Succeeded|Failed|Cancelled)"
  )
  export RUNNER_READY_PATTERNS_SET=1
fi

# Back-compat alias: if user exports PROJECTROOT (legacy/typo) and PROTECTROOT is unset, adopt it
if [[ -z "${PROTECTROOT:-}" && -n "${PROJECTROOT:-}" && -d "${PROJECTROOT}/.git" ]]; then
  export PROTECTROOT="${PROJECTROOT}"
  log_info "(compat) Using PROJECTROOT as PROTECTROOT: $PROTECTROOT"
fi

# --- Preflight checks ---
command -v gh >/dev/null 2>&1 || die "GitHub CLI 'gh' not found. Install https://cli.github.com/ and run 'gh auth login'."
gh auth status >/dev/null 2>&1 || die "'gh' not authenticated. Run: gh auth login"

# --- Determine target repo (mirror pull script resolution order) ---
REPO=""

# 1) From PROTECTROOT's origin
REPO="$(auto_detect_repo_from_protectroot)"
# 2) From env files (.env at ./, PROJECT_ROOT/.env, PROTECTROOT/.env)
if [[ -z "$REPO" ]]; then
  load_env_if_present
  REPO="$(derive_repo_from_env || true)"
fi
# 3) From current working dir's git origin
if [[ -z "$REPO" ]]; then
  REPO="$(derive_repo_from_pwd_git || true)"
  # If we resolved from PWD but PROTECTROOT isn't set, set it for downstream helpers
  if [[ -z "${PROTECTROOT:-}" ]]; then
    PROTECTROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
    [[ -n "$PROTECTROOT" ]] && export PROTECTROOT
  fi
fi

[[ -z "$REPO" ]] && die "Could not determine target repo. Set GITHUB_REPO in .env or export PROTECTROOT, or run inside a git repo."

echo "Repo:            $REPO"
echo "Branch:          ${BRANCH:-<current local branch>}"
echo "Commit message:  $COMMIT_MESSAGE"
echo

# --- Ensure env loaded (for runner setup vars like COMPANY_TOKEN / REPO_PATH) ---
load_env_if_present

# --- Ensure self-hosted runner container (non-fatal) ---
echo "[runner-check] Ensuring self-hosted runner container (set RUNNER_DEBUG=1 for verbose)."
if ! ensure_runner_container; then
  log_warn "Runner readiness check failed; proceeding anyway (a GitHub-hosted runner may pick up the job)."
else
  echo "➡️  Runner confirmed ready. Proceeding to trigger the workflow…"
fi

# --- Trigger workflow ---
CMD=(gh workflow run "$WORKFLOW_FILE" --repo "$REPO" -f "commit_message=$COMMIT_MESSAGE")
# Only pass branch if explicitly provided
if [[ -n "$BRANCH" ]]; then
  CMD+=(-f "branch=$BRANCH")
fi

echo "Triggering workflow: $WORKFLOW_FILE"
"${CMD[@]}"

echo "✅ Workflow triggered. To check progress:"
echo "   gh run list --repo $REPO --workflow $WORKFLOW_FILE"
