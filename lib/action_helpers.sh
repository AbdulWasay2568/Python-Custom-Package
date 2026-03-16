#!/usr/bin/env bash
# action_helpers.sh — reusable helpers for cross-repo scripts
# Load with: source "<PROJECT_ROOT>/lib/action_helpers.sh"
# Expects the calling script to define SCRIPT_DIR and PROJECT_ROOT (recommended).

set -euo pipefail

# ----------------------------
# Logging
# ----------------------------
log_info()  { echo "[info] $*"; }
log_warn()  { echo "[warn] $*"  >&2; }
log_error() { echo "[error] $*" >&2; }

# ----------------------------
# Misc UX helpers
# ----------------------------
prompt_yes_no() {
  local prompt="${1:-Proceed?} [y/N]: "
  local reply=""
  read -r -p "$prompt" reply || true
  local reply_lc
  reply_lc="$(printf '%s' "$reply" | tr '[:upper:]' '[:lower:]')"
  case "$reply_lc" in
    y|yes) return 0 ;;
    *)     return 1 ;;
  esac
}

die() { echo "Error: $*"; exit 1; }

# ----------------------------
# Env loader
# ----------------------------
# Loads first-set-wins env vars from:
#   1) ./.env
#   2) $PROJECT_ROOT/.env
#   3) $PROTECTROOT/.env (if set)
# This function assumes SCRIPT_DIR/PROJECT_ROOT/PROTECTROOT are already set in the environment.
load_env_if_present() {
  local candidates=()
  candidates+=(".env")
  if [[ -n "${PROJECT_ROOT:-}" ]]; then
    candidates+=("${PROJECT_ROOT}/.env")
  elif [[ -n "${SCRIPT_DIR:-}" ]]; then
    # Fallback: parent of bin/ (maintains previous behavior)
    candidates+=("$(dirname "$SCRIPT_DIR")/.env")
  fi
  if [[ -n "${PROTECTROOT:-}" ]]; then
    candidates+=("${PROTECTROOT}/.env")
  fi

  local env_file
  local loaded=()
  for env_file in "${candidates[@]}"; do
    [[ -f "$env_file" ]] || continue
    # shellcheck disable=SC2162
    while IFS='=' read -r k v; do
      k="${k%%[[:space:]]*}"; k="${k##[[:space:]]*}"; [[ -z "$k" || "$k" == \#* ]] && continue
      v="${v%$'\r'}"; v="${v##[[:space:]]}"; v="${v%%[[:space:]]}";
      if [[ -z "${!k:-}" ]]; then
        if [[ ${#v} -ge 2 ]]; then
          if [[ ${v:0:1} == '"' && ${v: -1} == '"' ]]; then
            v="${v:1:-1}"
          elif [[ ${v:0:1} == "'" && ${v: -1} == "'" ]]; then
            v="${v:1:-1}"
          fi
        fi
        export "$k"="$v"
      fi
    done < <(grep -v '^[[:space:]]*#' "$env_file" | sed '/^[[:space:]]*$/d')
    loaded+=("$env_file")
  done

  if [[ -n "${RUNNER_DEBUG:-}" ]]; then
    log_info "Env files loaded (first-set wins): ${loaded[*]:-(none)}"
  fi
}

# ----------------------------
# Repo derivation helpers
# ----------------------------
auto_detect_repo_from_protectroot() {
  local repo=""
  if [[ -n "${PROTECTROOT:-}" && -d "$PROTECTROOT/.git" ]]; then
    local origin_url
    origin_url=$(git -C "$PROTECTROOT" remote get-url origin 2>/dev/null || true)
    if [[ -n "$origin_url" && "$origin_url" =~ github\.com[:/]+([^/]+)/([^.]+)(\.git)?$ ]]; then
      repo="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    fi
  fi
  printf '%s' "$repo"
}

derive_repo_from_env() {
  local owner repo
  owner="${GITHUB_OWNER:-Bridge-Placement}"
  if [[ -n "${GITHUB_REPO:-}" ]]; then
    repo="$owner/$GITHUB_REPO"
    printf '%s' "$repo"
  fi
}

derive_repo_from_pwd_git() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local origin_url
    origin_url=$(git remote get-url origin 2>/dev/null || true)
    if [[ -n "$origin_url" && "$origin_url" =~ github\.com[:/]+([^/]+)/([^.]+)(\.git)?$ ]]; then
      printf '%s' "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    fi
  fi
}

# ----------------------------
# Self-hosted GitHub runner helpers
# ----------------------------
# Defaults (caller can override via env before calling ensure_runner_container)
: "${RUNNER_OWNER:=Bridge-Placement}"
: "${RUNNER_SETUP_SCRIPT_REL:=etc/setup-github-runner.sh}"
: "${RUNNER_START_TIMEOUT_SEC:=180}"
: "${RUNNER_LOG_POLL_INTERVAL:=5}"

# Array of readiness phrases (caller may override)
if [[ -z "${RUNNER_READY_PATTERNS_SET:-}" ]]; then
  # mark that we've set defaults to avoid reassigning if sourced twice
  # Added generic job completion regex so any finished job (Succeeded/Failed/Cancelled) counts as ready.
  # Pattern prefix 'regex:' enables regex evaluation in _ready_text_indicates_ready.
  declare -a RUNNER_READY_PATTERNS=(
    "Listening for Jobs" \
    "Runner reconnected" \
    "regex:Job .* completed with result: (Succeeded|Failed|Cancelled)" \
    "regex:completed with result: (Succeeded|Failed|Cancelled)"
  )
  export RUNNER_READY_PATTERNS_SET=1
fi

# returns 0 if any readiness phrase is present in the provided text
_ready_text_indicates_ready() {
  local text="$1"
  local pat
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

# Ensure a self-hosted runner container exists and is ready.
# Relies on:
#   - RUNNER_OWNER, RUNNER_SETUP_SCRIPT_REL, RUNNER_START_TIMEOUT_SEC, RUNNER_LOG_POLL_INTERVAL
#   - PROJECT_ROOT (for resolving setup script)
#   - Optional: GITHUB_REPO / REPO (owner/repo), PROTECTROOT
ensure_runner_container() {
  local owner_name="${RUNNER_OWNER}" repo_name derived=0

  # If docker missing, skip (non-fatal)
  if ! command -v docker >/dev/null 2>&1; then
    log_warn "Docker not found; skipping self-hosted runner setup."
    return 0
  fi

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

  # Exists?
  local exists=0
  if docker ps -a --format '{{.Names}}' | grep -qx "$container"; then
    exists=1
  fi

  # Running?
  local running=0
  if [[ $exists -eq 1 ]]; then
    if [[ "$(docker inspect -f '{{.State.Running}}' "$container" 2>/dev/null || echo false)" == "true" ]]; then
      running=1
    fi
  fi

  if [[ $running -eq 1 ]]; then
    log_info "Container '$container' is already running."
  else
    if [[ $exists -eq 1 ]]; then
      log_info "Container '$container' exists but is not running. Starting it now…"
      if ! docker start "$container" >/dev/null; then
        log_warn "Failed to start existing container. Removing and recreating…"
        docker rm -f "$container" >/dev/null 2>&1 || true
        exists=0
      fi
    fi

    if [[ $exists -eq 0 ]]; then
      log_info "No container found. Bringing up a new runner via '$RUNNER_SETUP_SCRIPT_REL'…"
      echo "🛠️  Making the GitHub runner container up for $owner_name/$repo_name …"
      local setup_script="${PROJECT_ROOT:-.}/$RUNNER_SETUP_SCRIPT_REL"
      if [[ ! -x "$setup_script" ]]; then
        log_error "Setup script not found or not executable: $setup_script"
        return 1
      fi

      # Ensure env for setup
      [[ -z "${GITHUB_REPO:-}" ]] && export GITHUB_REPO="$repo_name"
      [[ -z "${GITHUB_OWNER:-}" ]] && export GITHUB_OWNER="$owner_name"

      # Attempt to auto-derive REPO_PATH if missing
      if [[ -z "${REPO_PATH:-}" ]]; then
        if [[ -n "${PROTECTROOT:-}" && -d "${PROTECTROOT}/.git" ]]; then
          export REPO_PATH="${PROTECTROOT}"
          [[ -n "${RUNNER_DEBUG:-}" ]] && log_info "Derived REPO_PATH from PROTECTROOT: $REPO_PATH"
        else
          local git_root
          git_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
          if [[ -n "$git_root" && -d "$git_root/.git" ]]; then
            export REPO_PATH="$git_root"
            [[ -n "${RUNNER_DEBUG:-}" ]] && log_info "Derived REPO_PATH from current git root: $REPO_PATH"
          fi
        fi
      fi

      # Require token & path
      local missing_vars=()
      [[ -z "${COMPANY_TOKEN:-}" ]] && missing_vars+=(COMPANY_TOKEN)
      [[ -z "${REPO_PATH:-}" ]] && missing_vars+=(REPO_PATH)
      if (( ${#missing_vars[@]} > 0 )); then
        log_warn "Cannot create runner container; missing env: ${missing_vars[*]}. Export them or set RUNNER_DEBUG=1 for guidance."
        return 0
      fi

      if ! "$setup_script"; then
        log_error "Runner setup script failed."
        return 1
      fi
    fi
  fi

  # Wait for readiness (enhanced: initial tail + fallback broader scan)
  log_info "Waiting for runner readiness (timeout ${RUNNER_START_TIMEOUT_SEC}s)…"
  local start_ts now_ts elapsed since_arg="30s" logs_text fallback_checked=0 tail_lines
  start_ts=$(date +%s)

  # Quick initial tail (covers already-idle runner whose last readiness line is old)
  logs_text="$(docker logs --tail 250 "$container" 2>/dev/null || true)"
  if _ready_text_indicates_ready "$logs_text"; then
    log_info "Runner is ready (initial tail)."
    echo "✅ Runner is up. Moving towards the job you wanted to run…"
    return 0
  fi

  while true; do
    logs_text="$(docker logs --since "$since_arg" "$container" 2>/dev/null || true)"
    if _ready_text_indicates_ready "$logs_text"; then
      log_info "Runner is ready."
      echo "✅ Runner is up. Moving towards the job you wanted to run…"
      break
    fi
    now_ts=$(date +%s)
    elapsed=$(( now_ts - start_ts ))

    # Fallback scan of a larger recent tail once after a short grace period
    if (( fallback_checked == 0 && elapsed >= (RUNNER_LOG_POLL_INTERVAL * 2) )); then
      tail_lines=$(( 500 + RUNNER_LOG_POLL_INTERVAL * 40 ))
      logs_text="$(docker logs --tail "$tail_lines" "$container" 2>/dev/null || true)"
      if _ready_text_indicates_ready "$logs_text"; then
        log_info "Runner is ready (fallback tail)."
        echo "✅ Runner is up. Moving towards the job you wanted to run…"
        break
      fi
      fallback_checked=1
    fi

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
