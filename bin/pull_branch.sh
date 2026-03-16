#!/usr/bin/env bash
# pull_branch.sh — trigger workflows in a *target* repo while running from a shared repo
# Usage: ./pull_branch.sh <target-branch>

set -euo pipefail

# Resolve script + project roots early (script is expected to live in bin/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source reusable helpers
# shellcheck source=/dev/null
. "$PROJECT_ROOT/lib/action_helpers.sh"

# Provide backward-compatible alias: PROJECTROOT -> PROTECTROOT
if [[ -z "${PROTECTROOT:-}" && -n "${PROJECTROOT:-}" ]]; then
  if [[ -d "${PROJECTROOT}/.git" ]]; then
    PROTECTROOT="${PROJECTROOT}"
    export PROTECTROOT
    echo "(info) Using PROJECTROOT as PROTECTROOT: $PROTECTROOT" >&2
  fi
fi

# --- Runner defaults (override with env if needed) ---
: "${RUNNER_OWNER:=Bridge-Placement}"
: "${RUNNER_START_TIMEOUT_SEC:=180}"
: "${RUNNER_LOG_POLL_INTERVAL:=5}"
# Default readiness patterns (can be overridden by exporting RUNNER_READY_PATTERNS before running)
if [[ -z "${RUNNER_READY_PATTERNS_SET:-}" ]]; then
  # Generic patterns with regex: prefix (supported by action_helpers.sh) to detect any finished job state.
  declare -a RUNNER_READY_PATTERNS=(
    "Listening for Jobs" \
    "Runner reconnected" \
    "regex:Job .* completed with result: (Succeeded|Failed|Cancelled)" \
    "regex:completed with result: (Succeeded|Failed|Cancelled)"
  )
  export RUNNER_READY_PATTERNS_SET=1
fi
: "${RUNNER_SETUP_SCRIPT_REL:=etc/setup-github-runner.sh}"

# --- Defaults (override with flags) ---
PUSH_WORKFLOW_FILE=".github/workflows/update2.yml"
STASH_WORKFLOW_FILE=".github/workflows/pull-branch.yml"
REPO=""                 # owner/repo; auto-detected via PROTECTROOT if empty
REF=""                  # workflow ref (branch/tag/sha). Blank = repo default branch
WATCH=1
INTERACTIVE=1
REQUIRE_RUNNER=0          # when set (--require-runner) fail if self-hosted runner not ready
ENV_FILE_NAMES=${ENV_FILE_NAMES:-".env example.env"}  # (kept for backward compat; loader ignores names and scans well-known places)

usage() {
  cat <<EOF
Usage: $(basename "$0") <target-branch> [options]

Positional:
  <target-branch>            Branch to switch to (passed to workflows / or for local update)

Options:
  -r, --repo <owner/repo>    Target GitHub repository (default: auto-detect from PROTECTROOT / PROJECTROOT)
                             Fallback order if not provided:
                               1. PROTECTROOT (or aliased PROJECTROOT) git remote origin
                               2. .env (GITHUB_OWNER + GITHUB_REPO or Bridge-Placement + GITHUB_REPO)
                               3. Current directory git remote origin
  --push <path|name>         Push workflow file or name (default: ${PUSH_WORKFLOW_FILE})
  --stash <path|name>        Stash workflow file or name (default: ${STASH_WORKFLOW_FILE})
  --ref <ref>                Git ref for the workflow run (branch/tag/SHA). Default: repo default branch
  --no-watch                 Trigger only; don't watch logs
  --no-interactive           Skip interactive prompts; always trigger push workflow
  --require-runner           Fail if self-hosted runner container can't be ensured
  (env) ENV_FILE_NAMES       Space-separated env file basenames to scan (deprecated; loader scans standard locations)
  -h, --help                 Show this help

Examples:
  PROTECTROOT=\$HOME/code/ezbot \\
    $(basename "$0") dev-fizza --push ".github/workflows/pull-branch.yml"

  $(basename "$0") main -r "your-org/ezbot" --push ".github/workflows/update2.yml"
EOF
}

# --- Parse args ---
if [[ $# -lt 1 ]]; then usage; exit 1; fi
TARGET_BRANCH="$1"; shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--repo) REPO="$2"; shift 2 ;;
    --push) PUSH_WORKFLOW_FILE="$2"; shift 2 ;;
    --stash) STASH_WORKFLOW_FILE="$2"; shift 2 ;;
    --ref) REF="$2"; shift 2 ;;
    --no-watch) WATCH=0; shift ;;
    --no-interactive) INTERACTIVE=0; shift ;;
    --require-runner) REQUIRE_RUNNER=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

# --- Preflight checks ---
command -v gh >/dev/null 2>&1 || die "GitHub CLI 'gh' not found. Install https://cli.github.com/ and run 'gh auth login'."
gh auth status >/dev/null 2>&1 || die "'gh' not authenticated. Run: gh auth login"

# Determine target repo (extended fallback)
if [[ -z "$REPO" ]]; then
  REPO="$(auto_detect_repo_from_protectroot)"
fi
if [[ -z "$REPO" ]]; then
  load_env_if_present
  REPO="$(derive_repo_from_env || true)"
fi
if [[ -z "$REPO" ]]; then
  REPO="$(derive_repo_from_pwd_git || true)"
  if [[ -z "${PROTECTROOT:-}" && -n "$REPO" ]]; then
    PROTECTROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
  fi
fi
[[ -z "$REPO" ]] && die "Could not determine target repo. Provide --repo owner/repo or set GITHUB_REPO in .env or export PROTECTROOT (or PROJECTROOT)."

# Determine ref (default to current branch *of the target repo* if possible)
if [[ -z "$REF" && -n "${PROTECTROOT:-}" && -d "$PROTECTROOT/.git" ]]; then
  REF="$(git -C "$PROTECTROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  [[ "$REF" == "HEAD" ]] && REF=""
fi

# Informational
if [[ -n "${PROTECTROOT:-}" && -d "$PROTECTROOT" ]]; then
  echo "Using PROTECTROOT: $PROTECTROOT"
else
  echo "PROTECTROOT not set; continuing without changing directories."
fi

echo "Repository:       $REPO"
echo "Target branch:    $TARGET_BRANCH"
echo "Ref:              ${REF:-<default branch>}"
echo

# --- Interactive / non-interactive flow selection ---
SELECTED_WORKFLOW=""
ACTION_MODE="workflow" # or "local_update"

if [[ $INTERACTIVE -eq 1 ]]; then
  echo "⚠️  DO YOU HAVE LOCAL CHANGES TO COMMIT BEFORE SWITCHING BRANCHES? ⚠️"
  if prompt_yes_no "Answer YES if there ARE changes, NO if there are NOT"; then
    echo
    echo "✅ You indicated there ARE changes."
    SELECTED_WORKFLOW="$PUSH_WORKFLOW_FILE"
    ACTION_MODE="workflow"
  else
    echo
    echo "WARNING: BY SWITCHING BRANCHES YOU MAY LOSE YOUR WORK"
    echo "💀 ANY CHANGES MADE TO FILES NOT UNDER GIT CONTROL WILL BE LOST."
    echo
    if prompt_yes_no "DO YOU WANT TO UPDATE."; then
      ACTION_MODE="local_update"
      SELECTED_WORKFLOW=""
    else
      echo "Aborted by user."
      exit 0
    fi
  fi
else
  SELECTED_WORKFLOW="$PUSH_WORKFLOW_FILE"
  ACTION_MODE="workflow"
fi

# --- Local update path works inside PROTECTROOT repo only ---
if [[ "$ACTION_MODE" == "local_update" ]]; then
  [[ -z "${PROTECTROOT:-}" ]] && die "local_update requires PROTECTROOT (or PROJECTROOT) to point at a git repo."
  if ! git -C "$PROTECTROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    die "PROTECTROOT (resolved) is not a git repository: $PROTECTROOT"
  fi

  echo
  echo "➡️  Performing local update in: $PROTECTROOT (stash + checkout $TARGET_BRANCH + pull)"
  CURRENT_BRANCH="$(git -C "$PROTECTROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
  echo "Current branch: $CURRENT_BRANCH"

  if git -C "$PROTECTROOT" diff --quiet --ignore-submodules HEAD \
     && git -C "$PROTECTROOT" diff --quiet --ignore-submodules --cached \
     && [[ -z "$(git -C "$PROTECTROOT" ls-files --others --exclude-standard)" ]]; then
    echo "No local changes to stash."
  else
    STASH_MSG="auto-stash before switching to $TARGET_BRANCH ($(date -u +%Y-%m-%dT%H:%M:%SZ))"
    git -C "$PROTECTROOT" stash push -u -m "$STASH_MSG"
    echo "Created stash: $STASH_MSG"
  fi

  echo "Fetching origin/$TARGET_BRANCH ..."
  if git -C "$PROTECTROOT" fetch origin "$TARGET_BRANCH" >/dev/null 2>&1; then
    if git -C "$PROTECTROOT" show-ref --verify --quiet "refs/heads/$TARGET_BRANCH"; then
      echo "Checking out existing local branch $TARGET_BRANCH"
      git -C "$PROTECTROOT" checkout "$TARGET_BRANCH"
    else
      if git -C "$PROTECTROOT" ls-remote --exit-code --heads origin "$TARGET_BRANCH" >/dev/null 2>&1; then
        echo "Creating local branch $TARGET_BRANCH tracking origin/$TARGET_BRANCH"
        git -C "$PROTECTROOT" checkout -b "$TARGET_BRANCH" "origin/$TARGET_BRANCH"
      else
        echo "Error: Remote branch origin/$TARGET_BRANCH not found." >&2
        echo "Leaving you on $CURRENT_BRANCH (stash preserved)." >&2
        exit 1
      fi
    fi
    echo "Pulling latest changes..."
    git -C "$PROTECTROOT" pull --ff-only origin "$TARGET_BRANCH" || {
      echo "Fast-forward pull failed. You may need to investigate (rebase/merge)." >&2
    }
  else
    echo "Warning: fetch failed for origin/$TARGET_BRANCH. Attempting local checkout only." >&2
    if git -C "$PROTECTROOT" show-ref --verify --quiet "refs/heads/$TARGET_BRANCH"; then
      git -C "$PROTECTROOT" checkout "$TARGET_BRANCH"
    else
      echo "Error: Can't proceed; branch $TARGET_BRANCH not available locally and fetch failed." >&2
      exit 1
    fi
  fi

  echo
  echo "✅ Branch switched to $(git -C "$PROTECTROOT" rev-parse --abbrev-ref HEAD)."
  echo "Use 'git -C \"$PROTECTROOT\" stash list' to see any created stash. To apply the most recent stash:"
  echo "  git -C \"$PROTECTROOT\" stash pop"
  echo "Done."
  exit 0
fi

# --- Cross-repo workflow trigger path ---
echo
echo "Triggering workflow in repo '$REPO': ${SELECTED_WORKFLOW}"

# Ensure env vars available (for e.g., COMPANY_TOKEN/REPO_PATH used by runner setup)
load_env_if_present

# Ensure runner container (non-fatal unless --require-runner)
echo "[runner-check] Ensuring self-hosted runner container (set RUNNER_DEBUG=1 for verbose)."
if ! ensure_runner_container; then
  if [[ $REQUIRE_RUNNER -eq 1 ]]; then
    echo "[runner-check] Runner requirement failed (--require-runner set). Aborting." >&2
    exit 1
  fi
  echo "[runner-check] Warning: runner readiness check failed; proceeding anyway (a GitHub-hosted runner may pick up the job)." >&2
else
  echo "➡️  Runner confirmed ready. Proceeding to trigger the pull-branch workflow…"
fi

CMD=(gh workflow run "$SELECTED_WORKFLOW" --repo "$REPO" -f "target_branch=$TARGET_BRANCH")
[[ -n "$REF" ]] && CMD+=(--ref "$REF")
"${CMD[@]}"

# Try to resolve newest run ID for this workflow and watch logs (optional)
sleep 2
RUN_ID="$(gh run list --repo "$REPO" --workflow "$SELECTED_WORKFLOW" --limit 1 \
  --json databaseId --jq '.[0].databaseId' 2>/dev/null || true)"

if [[ -z "$RUN_ID" || "$RUN_ID" == "null" ]]; then
  echo "Triggered, but couldn't resolve run ID. View runs with:"
  echo "  gh run list --repo $REPO --workflow \"$SELECTED_WORKFLOW\""
  exit 0
fi

echo "Run ID: $RUN_ID"

if [[ $WATCH -eq 1 ]]; then
  echo
  echo "Watching run logs (Ctrl-C to stop)..."
  gh run watch "$RUN_ID" --repo "$REPO" --exit-status
  echo
  echo "Logs:"
  gh run view "$RUN_ID" --repo "$REPO" --log
else
  echo "Not watching. To view later:"
  echo "  gh run watch $RUN_ID --repo $REPO --exit-status"
  echo "  gh run view  $RUN_ID --repo $REPO --log"
fi
