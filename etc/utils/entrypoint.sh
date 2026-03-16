#!/bin/bash
set -Eeuo pipefail

log(){ echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

cleanup() {
  log "🧹 Cleaning up runner registration..."
  cd /home/runner || true
  
  # Stop the runner gracefully first
  if [ -f .runner ] && [ -n "${COMPANY_TOKEN:-}" ]; then
    log "🛑 Removing runner registration from GitHub..."
    ./config.sh remove --unattended --token "${COMPANY_TOKEN}" || true
  fi
  
  # Clean up local configuration files
  rm -f .runner .credentials .credentials_rsaparams .path || true
  [ -d _work ] && rm -rf _work || true
  
  # Clean up Git credentials
  [ -f /tmp/git-credentials/.git-credentials ] && rm -f /tmp/git-credentials/.git-credentials
  [ -f /workspace/.git-credentials ] && rm -f /workspace/.git-credentials
  
  log "✅ Cleanup completed"
}
trap cleanup EXIT INT TERM

# ------------------------------------------------------------------------------
# CLI overrides so you can pass secrets/params at *run time*:
#   --pat <token> --owner <org_or_user> --repo <repo> --mode <org|repo>
#   --name <runner_name> --labels <csv>
while [ $# -gt 0 ]; do
  case "$1" in
    --pat)    COMPANY_TOKEN="$2"; shift 2 ;;
    --owner)  GITHUB_OWNER="$2"; shift 2 ;;
    --repo)   GITHUB_REPO="$2"; shift 2 ;;
    --mode)   REGISTRATION_MODE="$2"; shift 2 ;;
    --name)   RUNNER_NAME="$2"; shift 2 ;;
    --labels) RUNNER_LABELS="$2"; shift 2 ;;
    *) log "Unknown arg: $1"; shift ;;
  esac
done
# ------------------------------------------------------------------------------

# Optional: load PAT from a mounted file (safer than env)
if [ -z "${COMPANY_TOKEN:-}" ] && [ -n "${COMPANY_TOKEN_FILE:-}" ] && [ -f "$COMPANY_TOKEN_FILE" ]; then
  COMPANY_TOKEN="$(tr -d '\r\n' < "$COMPANY_TOKEN_FILE")"
fi

# Defaults (env can override)
RUNNER_WORKDIR="${RUNNER_WORKDIR:-/workspace}"
REGISTRATION_MODE="${REGISTRATION_MODE:-org}"

# Require after reading CLI/env/file
: "${COMPANY_TOKEN:?❌ COMPANY_TOKEN is required}"
: "${GITHUB_OWNER:?❌ GITHUB_OWNER is required}"

# Auto-detect architecture and set appropriate labels
ARCH=$(uname -m)
case "$ARCH" in
  x86_64) ARCH_LABEL="x64" ;;
  aarch64|arm64) ARCH_LABEL="arm64" ;;
  armv7l) ARCH_LABEL="arm" ;;
  *) ARCH_LABEL="unknown" ;;
esac

# Build comprehensive labels including architecture
BASE_LABELS="self-hosted,docker,linux"
RUNNER_LABELS="${RUNNER_LABELS:-${BASE_LABELS},${ARCH_LABEL}}"

# Normalize PAT (strip only CR/LF)
COMPANY_TOKEN="$(printf '%s' "$COMPANY_TOKEN" | tr -d '\r\n')"

# Debug token information (safely)
log "🔍 Debug: Token length: ${#COMPANY_TOKEN}"
log "🔍 Debug: Token prefix: ${COMPANY_TOKEN:0:4}..."
log "🔍 Debug: Token format check: $(echo "$COMPANY_TOKEN" | grep -E '^gh[ps]_[A-Za-z0-9]{36}$' >/dev/null && echo 'VALID FORMAT' || echo 'INVALID FORMAT')"
log "🏗️ Detected architecture: $ARCH -> $ARCH_LABEL"

# Build registration URL and API endpoint based on mode
if [ "${REGISTRATION_MODE}" = "org" ]; then
  REGISTRATION_URL="https://github.com/${GITHUB_OWNER}"
  API_ENDPOINT="https://api.github.com/orgs/${GITHUB_OWNER}/actions/runners/registration-token"
  log "🏢 Organization mode: Registering to organization ${GITHUB_OWNER}"
else
  : "${GITHUB_REPO:?❌ GITHUB_REPO is required for repo registration}"
  REGISTRATION_URL="https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}"
  API_ENDPOINT="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/runners/registration-token"
  log "📦 Repository mode: Registering to ${GITHUB_OWNER}/${GITHUB_REPO}"
fi

# Fetch GitHub login (to append to runner name)
GITHUB_LOGIN="$(curl -s -H "Authorization: Bearer ${COMPANY_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/user | jq -r '.login // empty')"
if [ -n "$GITHUB_LOGIN" ]; then
  GITHUB_LOGIN_CLEAN="$(printf '%s' "$GITHUB_LOGIN" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-')"
else
  GITHUB_LOGIN_CLEAN=""
fi

# Finalize runner name (auto-append login)
RUNNER_NAME="${RUNNER_NAME:-docker-runner}"
# if [ -n "$GITHUB_LOGIN_CLEAN" ]; then
#   RUNNER_NAME="${RUNNER_NAME}-${GITHUB_LOGIN_CLEAN}"
#   # Optional: also add a user:<login> label
#   RUNNER_LABELS="${RUNNER_LABELS}"
# fi

log "🚀 Starting GitHub Actions Runner"
log "Runner Name      : $RUNNER_NAME"
log "Work Directory   : $RUNNER_WORKDIR"
log "Labels           : $RUNNER_LABELS"
log "Registration URL : $REGISTRATION_URL"

cd /home/runner

# Clean up any existing runner configuration to prevent session conflicts
log "🧽 Performing thorough cleanup of old runner configuration..."
rm -f .runner .credentials .credentials_rsaparams
[ -d _work ] && rm -rf _work
[ -f .path ] && rm -f .path

# Optional: Try to remove any existing runner with the same name from GitHub
if [ -n "$COMPANY_TOKEN" ] && [ -n "$RUNNER_NAME" ]; then
  log "🗑️ Checking for existing runner registration..."
  
  if [ "$REGISTRATION_MODE" = "org" ]; then
    RUNNERS_RESPONSE=$(curl -s -H "Authorization: Bearer $COMPANY_TOKEN" \
      "https://api.github.com/orgs/${GITHUB_OWNER}/actions/runners" || echo '{"runners":[]}')
    
    if echo "$RUNNERS_RESPONSE" | jq -e '.runners' >/dev/null 2>&1; then
      EXISTING_RUNNER_ID=$(echo "$RUNNERS_RESPONSE" | jq -r ".runners[] | select(.name==\"$RUNNER_NAME\") | .id" 2>/dev/null || echo "")
    else
      log "⚠️ Cannot access organization runners API. This might mean:"
      log "   1. Your PAT needs 'admin:org' scope for organization runners"
      log "   2. Or try using repository mode instead (REGISTRATION_MODE=repo)"
      EXISTING_RUNNER_ID=""
    fi
  else
    RUNNERS_RESPONSE=$(curl -s -H "Authorization: Bearer $COMPANY_TOKEN" \
      "https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/runners" || echo '{"runners":[]}')
    
    if echo "$RUNNERS_RESPONSE" | jq -e '.runners' >/dev/null 2>&1; then
      EXISTING_RUNNER_ID=$(echo "$RUNNERS_RESPONSE" | jq -r ".runners[] | select(.name==\"$RUNNER_NAME\") | .id" 2>/dev/null || echo "")
    else
      log "⚠️ Cannot access repository runners API. Check your PAT has 'repo' scope."
      EXISTING_RUNNER_ID=""
    fi
  fi
  
  if [ -n "$EXISTING_RUNNER_ID" ] && [ "$EXISTING_RUNNER_ID" != "null" ]; then
    log "🗑️ Removing existing runner registration (ID: $EXISTING_RUNNER_ID)..."
    if [ "$REGISTRATION_MODE" = "org" ]; then
      curl -s -X DELETE -H "Authorization: Bearer $COMPANY_TOKEN" \
        "https://api.github.com/orgs/${GITHUB_OWNER}/actions/runners/$EXISTING_RUNNER_ID" || true
    else
      curl -s -X DELETE -H "Authorization: Bearer $COMPANY_TOKEN" \
        "https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/runners/$EXISTING_RUNNER_ID" || true
    fi
    sleep 2
  fi
fi

log "🛠️ Configuring runner (using manual token generation)..."

# Additional debugging
log "🔍 Debug: Environment variables check:"
log "🔍 Debug: COMPANY_TOKEN is set: $([ -n "$COMPANY_TOKEN" ] && echo 'YES' || echo 'NO')"
log "🔍 Debug: Registration URL: $REGISTRATION_URL"

# Test GitHub API access with the token
log "🔍 Debug: Testing GitHub API access..."
if [ "$REGISTRATION_MODE" = "org" ]; then
  curl -s -H "Authorization: Bearer $COMPANY_TOKEN" \
       -H "X-GitHub-Api-Version: 2022-11-28" \
       "https://api.github.com/orgs/${GITHUB_OWNER}" \
       | jq -r '.login // "API_ERROR"' \
       | { read result; log "🔍 Debug: API test result for org: $result"; }
else
  curl -s -H "Authorization: Bearer $COMPANY_TOKEN" \
       -H "X-GitHub-Api-Version: 2022-11-28" \
       "https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}" \
       | jq -r '.full_name // "API_ERROR"' \
       | { read result; log "🔍 Debug: API test result for repo: $result"; }
fi

# Get registration token manually
log "🔍 Debug: Obtaining registration token from: $API_ENDPOINT"
REGISTRATION_TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer $COMPANY_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "$API_ENDPOINT" \
  | jq -r '.token // empty')

if [ -z "$REGISTRATION_TOKEN" ]; then
  log "❌ Failed to obtain registration token"
  log "🔍 Debug: Check your GitHub PAT permissions:"
  if [ "$REGISTRATION_MODE" = "org" ]; then
    log "🔍 Debug: For organization mode, PAT needs 'admin:org' scope"
    log "🔍 Debug: Verify access at: https://github.com/organizations/${GITHUB_OWNER}/settings/actions/runners"
  else
    log "🔍 Debug: For repository mode, PAT needs 'repo' scope and admin access"
    log "🔍 Debug: Verify access at: https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/settings/actions/runners"
  fi
  exit 1
fi

log "🔍 Debug: Registration token obtained successfully (length: ${#REGISTRATION_TOKEN})"

# Configure Git credentials...
log "🔧 Configuring Git credentials..."
git config --global user.name "GitHub Runner"
git config --global user.email "runner@github.com"
git config --global credential.helper store
echo "https://oauth2:${COMPANY_TOKEN}@github.com" > /home/runner/.git-credentials
chmod 600 /home/runner/.git-credentials

log "✅ Git credentials configured"
cd /home/runner

# Set environment variables for GitHub Actions
export GITHUB_TOKEN="$COMPANY_TOKEN"
export GIT_TERMINAL_PROMPT=0
export GIT_ASKPASS=/bin/echo

# Use the registration token directly with config.sh
./config.sh \
  --url "$REGISTRATION_URL" \
  --token "$REGISTRATION_TOKEN" \
  --name "$RUNNER_NAME" \
  --work "$RUNNER_WORKDIR" \
  --labels "$RUNNER_LABELS" \
  --unattended \
  --replace
log "✅ Runner configured"

log "🏃 Runner listening for jobs..."
exec ./run.sh
