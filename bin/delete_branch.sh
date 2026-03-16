#!/usr/bin/env bash

set -euo pipefail

PROTECTED_BRANCHES="main master develop production staging" # space separated list
REMOTE="origin"
FORCE=0
REMOTE_ONLY=0
LOCAL_ONLY=0
ASSUME_YES=0
WITH_RUNNER=${ENSURE_RUNNER:-0}  # enable via --with-runner or ENSURE_RUNNER=1

# --- GitHub Runner Container Readiness Add-On (optional) ---
RUNNER_OWNER="${RUNNER_OWNER:-Bridge-Placement}"
RUNNER_READY_PATTERNS=(
  "Listening for Jobs" \
  "Runner reconnected" \
  "regex:Job .* completed with result: (Succeeded|Failed|Cancelled)" \
  "regex:completed with result: (Succeeded|Failed|Cancelled)"
)
RUNNER_SETUP_SCRIPT_REL="etc/setup-github-runner.sh"
RUNNER_START_TIMEOUT_SEC=${RUNNER_START_TIMEOUT_SEC:-180}
RUNNER_LOG_POLL_INTERVAL=${RUNNER_LOG_POLL_INTERVAL:-5}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

log_info()  { echo "[runner-check] $*"; }
log_warn()  { echo "[runner-check] $*" >&2; }
log_error() { echo "[runner-check] $*" >&2; }

_ready_text_indicates_ready() {
  local text="$1"
  for pat in "${RUNNER_READY_PATTERNS[@]}"; do
    if [[ "$pat" == regex:* ]]; then
      local rex="${pat#regex:}"
      if grep -Eq "$rex" <<<"$text"; then
        return 0
      fi
    else
      if grep -qF "$pat" <<<"$text"; then
        return 0
      fi
    fi
  done
  return 1
}

# Uses either GITHUB_REPO (repo name only) or REPO (owner/repo) to derive the container name new wkjndejewdlcsajl
ensure_runner_container() {
  local owner_name="$RUNNER_OWNER" repo_name derived=0

  if [[ -n "${GITHUB_REPO:-}" ]]; then
    repo_name="$GITHUB_REPO"
  elif [[ -n "${REPO:-}" && "$REPO" =~ ^([^/]+)/([^/]+)$ ]]; then
    owner_name="${BASH_REMATCH[1]}"
    repo_name="${BASH_REMATCH[2]}"
    derived=1
    [[ -n "${RUNNER_DEBUG:-}" ]] && log_info "Derived repo_name='$repo_name' owner='$owner_name' from REPO='$REPO'"
  else
    log_warn "No GITHUB_REPO/REPO; cannot determine runner container. Skipping self-hosted runner bring-up."
    return 0
  fi

  local container="github-runner-${owner_name}-${repo_name}"

  local exists=0 running=0
  if docker ps -a --format '{{.Names}}' | grep -qx "$container"; then
    exists=1
    if [[ "$(docker inspect -f '{{.State.Running}}' "$container" 2>/dev/null || echo false)" == "true" ]]; then
      running=1
    fi
  fi

  if [[ $running -eq 1 ]]; then
    log_info "Container '$container' is already running."
  else
    if [[ $exists -eq 1 ]]; then
      log_info "Container '$container' exists but not running. Starting it now…"
      if ! docker start "$container" >/dev/null; then
        log_warn "Failed to start existing container. Removing and recreating…"
        docker rm -f "$container" >/dev/null 2>&1 || true
        exists=0
      fi
    fi

    if [[ $exists -eq 0 ]]; then
      log_info "No container found. Bringing up a new runner via '$RUNNER_SETUP_SCRIPT_REL'…"
      echo "🛠️  Making the GitHub runner container up for $owner_name/$repo_name …"
      local setup_script="$PROJECT_ROOT/$RUNNER_SETUP_SCRIPT_REL"
      if [[ ! -x "$setup_script" ]]; then
        log_error "Setup script not found or not executable: $setup_script"
        return 1
      fi

      # Ensure setup has the repo/owner
      if [[ -z "${GITHUB_REPO:-}" ]]; then export GITHUB_REPO="$repo_name"; fi
      if [[ -z "${GITHUB_OWNER:-}" ]]; then export GITHUB_OWNER="$owner_name"; fi

      # Require token & path to register the runner properly
      if [[ -z "${COMPANY_TOKEN:-}" || -z "${REPO_PATH:-}" ]]; then
        log_warn "Missing COMPANY_TOKEN or REPO_PATH; cannot create runner container. Skipping creation."
        return 0
      fi

      if ! "$setup_script"; then
        log_error "Runner setup script failed."
        return 1
      fi
    fi
  fi

  log_info "Waiting for runner readiness (timeout ${RUNNER_START_TIMEOUT_SEC}s)…"
  local start_ts now_ts elapsed since_arg="30s" logs_text
  start_ts=$(date +%s)
  while true; do
    logs_text="$(docker logs --since "$since_arg" "$container" 2>/dev/null || true)"
    if _ready_text_indicates_ready "$logs_text"; then
      log_info "Runner is ready."
      echo "✅ Runner is up. Proceeding with branch deletion…"
      break
    fi
    now_ts=$(date +%s)
    elapsed=$(( now_ts - start_ts ))
    if (( elapsed >= RUNNER_START_TIMEOUT_SEC )); then
      log_error "Timeout (${RUNNER_START_TIMEOUT_SEC}s) waiting for runner readiness."
      return 1
    fi
    echo "[runner-check] Still waiting… (${elapsed}s)"
    sleep "$RUNNER_LOG_POLL_INTERVAL"
    since_arg="${RUNNER_LOG_POLL_INTERVAL}s"
  done
  return 0
}

usage() {
	cat <<EOF
Delete a local and/or remote Git branch safely.

Usage: $(basename "$0") <branch> [options]

Options:
	-r <remote>     Remote name (default: origin)
	--remote-only   Delete only the remote branch
	--local-only    Delete only the local branch
	-f, --force     Force delete (git branch -D / remote --force)
	-y              Assume yes (no interactive prompt)
	--with-runner   Ensure the self-hosted GitHub runner container is up before proceeding
	-h, --help      Show this help

Safeguards:
	Will refuse to delete protected branches: $PROTECTED_BRANCHES
	Will refuse if you are currently checked out on the target branch.
EOF
}

die() { echo "[ERR] $*" >&2; exit 1; }
info() { echo "[INFO] $*" >&2; }
warn() { echo "[WARN] $*" >&2; }

parse_args() {
	[[ $# -gt 0 ]] || { usage; exit 1; }
	TARGET_BRANCH=""
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-h|--help) usage; exit 0;;
			-r) shift; REMOTE=${1:-}; [[ -n "$REMOTE" ]] || die "-r requires a value";;
			--remote-only) REMOTE_ONLY=1;;
			--local-only) LOCAL_ONLY=1;;
			-f|--force) FORCE=1;;
			-y) ASSUME_YES=1;;
			--with-runner) WITH_RUNNER=1;;
			-*) die "Unknown option: $1";;
			*) if [[ -z "$TARGET_BRANCH" ]]; then TARGET_BRANCH="$1"; else die "Branch already specified as $TARGET_BRANCH (extra arg $1)"; fi;;
		esac
		shift || true
	done
	[[ -n "${TARGET_BRANCH:-}" ]] || die "Branch name required"
	if [[ $REMOTE_ONLY -eq 1 && $LOCAL_ONLY -eq 1 ]]; then
		die "Cannot specify both --remote-only and --local-only"
	fi
}

confirm() {
	local prompt="$1" ans
	if [[ $ASSUME_YES -eq 1 ]]; then return 0; fi
	read -r -p "$prompt [y/N]: " ans || true
	[[ "$ans" =~ ^[Yy]([Ee][Ss])?$ ]]
}

ensure_git_repo() {
	git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "Not inside a git repository"
}

# Derive owner/repo and repo-name to support runner bring-up (if requested)
derive_repo_vars() {
  local origin_url
  if origin_url=$(git remote get-url "$REMOTE" 2>/dev/null); then
    if [[ "$origin_url" =~ github\.com[:/]+([^/]+)/([^.]+)(\.git)?$ ]]; then
      REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
      # Export for ensure_runner_container if GITHUB_REPO not already set
      if [[ -z "${GITHUB_REPO:-}" ]]; then export GITHUB_REPO="${BASH_REMATCH[2]}"; fi
      if [[ -z "${GITHUB_OWNER:-}" ]]; then export GITHUB_OWNER="${BASH_REMATCH[1]}"; fi
    fi
  fi
}

prevent_protected() {
	for p in $PROTECTED_BRANCHES; do
		if [[ "$TARGET_BRANCH" == "$p" ]]; then
			die "Refusing to delete protected branch '$TARGET_BRANCH'"
		fi
	done
}

prevent_current_branch() {
	local current
	current=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")
	if [[ "$current" == "$TARGET_BRANCH" ]]; then
		die "You are currently on branch '$TARGET_BRANCH'. Checkout another branch first."
	fi
}

delete_local() {
	if git rev-parse --verify --quiet "$TARGET_BRANCH" >/dev/null; then
		if [[ $FORCE -eq 1 ]]; then
			info "Force deleting local branch $TARGET_BRANCH"
			git branch -D "$TARGET_BRANCH"
		else
			info "Deleting local branch $TARGET_BRANCH"
			git branch -d "$TARGET_BRANCH" || {
				warn "Normal delete failed (unmerged?). Re-run with -f to force."
				return 1
			}
		fi
	else
		warn "Local branch '$TARGET_BRANCH' not found; skipping"
	fi
}

delete_remote() {
	if git ls-remote --exit-code "$REMOTE" "refs/heads/$TARGET_BRANCH" >/dev/null 2>&1; then
		if [[ $FORCE -eq 1 ]]; then
			info "Force deleting remote branch $REMOTE/$TARGET_BRANCH"
			git push "$REMOTE" --delete "$TARGET_BRANCH" 2>/dev/null || git push "$REMOTE" ":$TARGET_BRANCH"
		else
			info "Deleting remote branch $REMOTE/$TARGET_BRANCH"
			git push "$REMOTE" --delete "$TARGET_BRANCH" 2>/dev/null || git push "$REMOTE" ":$TARGET_BRANCH"
		fi
	else
		warn "Remote branch '$REMOTE/$TARGET_BRANCH' not found; skipping"
	fi
}

main() {
	parse_args "$@"
	ensure_git_repo
	derive_repo_vars
	prevent_protected
	prevent_current_branch
	info "Fetching latest refs from $REMOTE"
	git fetch --prune "$REMOTE" >/dev/null 2>&1 || warn "Fetch failed (continuing)"

  # Optional: ensure self-hosted runner
  if [[ "$WITH_RUNNER" -eq 1 ]]; then
    echo "[runner-check] Ensuring self-hosted runner container (set RUNNER_DEBUG=1 for verbose)."
    if ! ensure_runner_container; then
      echo "[runner-check] Warning: runner readiness check failed; continuing branch delete anyway." >&2
    else
      echo "➡️  Runner confirmed ready. Proceeding with deletion…"
    fi
  fi

	local actions=""
	if [[ $LOCAL_ONLY -eq 1 ]]; then actions="local"; elif [[ $REMOTE_ONLY -eq 1 ]]; then actions="remote"; else actions="local+remote"; fi
	if ! confirm "Confirm deletion of $actions branch '$TARGET_BRANCH' (remote: $REMOTE, force: $FORCE)"; then
		info "Aborted by user"
		exit 0
	fi

	local status=0
	if [[ $REMOTE_ONLY -eq 1 ]]; then
		delete_remote || status=$?
	elif [[ $LOCAL_ONLY -eq 1 ]]; then
		delete_local || status=$?
	else
		delete_local || status=$?
		delete_remote || status=$?
	fi

	if [[ $status -eq 0 ]]; then
		info "Done"
	else
		warn "Completed with non-fatal issues"
	fi
}

main "$@"
