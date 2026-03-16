#!/usr/bin/env bash

# GitHub Runner Setup Script
# This script loads the Docker image and sets up a GitHub runner container

set -e  # Exit on any error

# -----------------------------------------------------------------------------
# Non‑interactive mode customization
# Requirements (env vars):
#   GITHUB_REPO      (name of repository inside Bridge-Placement org)
#   COMPANY_TOKEN    (company token with repo + workflow scopes)
# Optional env vars:
#   REPO_PATH        (path to local git repository; defaults to CWD)
#   RUNNER_LABELS    (additional comma-separated labels; user label is auto-added)
# Behavior:
#   - Owner/org is fixed to "Bridge-Placement" (not overridden)
#   - Git user.name (from local repo, then global, else $USER) is appended to:
#       * Runner name: runner-<sanitized_git_user>-<hostname>
#       * Labels: adds user-<sanitized_git_user>
#   - Script is fully non-interactive; it will exit with error if required
#     inputs are missing or invalid.
# -----------------------------------------------------------------------------

# Detect platform variants
IS_WINDOWS="false"   # Git Bash / MSYS / MINGW / Cygwin
IS_WSL="false"       # Windows Subsystem for Linux
UNAME_S="$(uname -s 2>/dev/null || echo unknown)"
case "$UNAME_S" in
    MINGW*|MSYS*|CYGWIN*) IS_WINDOWS="true" ;;
esac
if grep -qi 'microsoft' /proc/version 2>/dev/null; then
    IS_WSL="true"
fi

# Normalize a path possibly entered in Windows form (e.g. C:\Users\name\repo)
normalize_path() {
    local p="$1"
    [[ -z $p ]] && echo "" && return 0
    # Trim surrounding quotes
    p="${p%\"}"; p="${p#\"}"; p="${p%\'}"; p="${p#\'}"
    # Expand ~
    if [[ $p == ~* ]]; then
        p="${p/#~/$HOME}"
    fi
    # Replace backslashes with forward slashes first
    p="${p//\\/\/}"
    # Detect Windows drive letter (C:/path or C:Path or C:\Path)
    if [[ $p =~ ^([A-Za-z]):/?(.*)$ ]]; then
        local driveLower
        driveLower=$(echo "${BASH_REMATCH[1]}" | tr 'A-Z' 'a-z')
        local rest="${BASH_REMATCH[2]}"
        rest="${rest#/}"
        if [[ "$IS_WSL" == "true" ]]; then
            p="/mnt/${driveLower}/${rest}"
        else
            p="/${driveLower}/${rest}"
        fi
    fi
    p="$(echo "$p" | sed -e 's#//*#/#g')"
    echo "$p"
}

# Pause on exit (only when run in Windows interactive shell and user double‑clicked)
pause_before_exit() {
    if [[ ("$IS_WINDOWS" == "true" || "$IS_WSL" == "true") && -t 1 ]]; then
        echo ""
        read -r -p "Press Enter to close..." _dummy
    fi
}
trap pause_before_exit EXIT

# Colors for output (fallback to no color if terminal doesn't support)
if [[ -t 1 && -z "$NO_COLOR" && "$TERM" != "dumb" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Auto-load .env files (non-destructive). Search order (first to last):
#  1. etc/.env (script directory containing this setup script)
#  2. project root .env (one level up from etc)
#  3. current working directory .env (in case script invoked from elsewhere)
load_env_file() {
    local f="$1"
    [[ ! -f "$f" ]] && return 0
    print_info "Loading environment from $f (existing exported vars preserved)"
    while IFS='=' read -r _key _value; do
        key="${_key%%[[:space:]]*}"; key="${key##[[:space:]]*}"  
        [[ -z "$key" || "$key" == \#* ]] && continue
        if [[ -n "${!key}" ]]; then
            continue
        fi
        value="${_value}";
        value="${value%$'\r'}"
        value="${value##[[:space:]]}"; value="${value%%[[:space:]]}";
        if [[ ${value:0:1} == '"' && ${value: -1} == '"' ]]; then
            value="${value:1:-1}"
        elif [[ ${value:0:1} == "'" && ${value: -1} == "'" ]]; then
            value="${value:1:-1}"
        fi
        export "$key"="$value"
    done < <(grep -v '^[[:space:]]*#' "$f" | sed '/^[[:space:]]*$/d')
}

load_env_file "$SCRIPT_DIR/.env"
load_env_file "$PROJECT_ROOT/.env"
if [[ "$PWD" != "$PROJECT_ROOT" ]]; then
    load_env_file "$PWD/.env"
fi

# Find Docker image (any .tar.gz file in the etc directory where this script resides)
DOCKER_IMAGE_PATH=""
for file in "$SCRIPT_DIR"/*.tar.gz; do
    if [ -f "$file" ]; then
        DOCKER_IMAGE_PATH="$file"
        break
    fi
done

print_info "Path of image archive: $DOCKER_IMAGE_PATH"
print_info "GitHub Runner Setup Script (non-interactive)"
print_info "Environment: uname=$UNAME_S windows=$IS_WINDOWS wsl=$IS_WSL"
echo "=================================="

# Basic command availability checks (cross-platform)
for cmd in docker git sed grep tr uname; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
                print_error "Required command '$cmd' not found in PATH. Install it and retry."
                exit 1
        fi
done

# Resolve a host identifier (hostname may differ on Windows shells)
HOST_ID=$(hostname 2>/dev/null || echo "")
if [[ -z "$HOST_ID" && -n "$COMPUTERNAME" ]]; then
    HOST_ID="$COMPUTERNAME"
fi
if [[ -z "$HOST_ID" ]]; then
    HOST_ID="unknown-host"
fi

# Step 1: Check if Docker is running
print_info "Checking if Docker is running..."
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi
print_success "Docker is running"

# Step 2: Load Docker image
if [ -z "$DOCKER_IMAGE_PATH" ]; then
    print_error "No Docker image (.tar.gz file) found in the etc/ folder"
    print_error "Please download the Docker image from Google Drive and place it in the etc/ folder"
    exit 1
fi

print_info "Loading Docker image from $DOCKER_IMAGE_PATH"
if [ ! -f "$DOCKER_IMAGE_PATH" ]; then
    print_error "Docker image not found at $DOCKER_IMAGE_PATH"
    print_error "Please download the Docker image from Google Drive and place it in the etc/ folder"
    exit 1
fi

print_info "Extracting and loading Docker image (this may take a moment)..."
set +e
LOAD_OUTPUT=$(gunzip -c "$DOCKER_IMAGE_PATH" 2>/dev/null | docker load 2>&1)
LOAD_STATUS=$?
set -e
if [ $LOAD_STATUS -eq 0 ]; then
    IMAGE_NAME=$(printf "%s\n" "$LOAD_OUTPUT" | sed -n 's/^Loaded image: //p' | tail -n1)
    print_success "Docker image loaded successfully${IMAGE_NAME:+: $IMAGE_NAME}"
else
    print_warning "Streaming gunzip failed; attempting gzip -dc fallback..."
    if gzip -dc "$DOCKER_IMAGE_PATH" 2>/dev/null | docker load; then
        print_success "Docker image loaded (gzip fallback)"
    else
        print_warning "Falling back to temporary decompression..."
        TEMP_TAR="${DOCKER_IMAGE_PATH%.gz}"
        if [[ ! -f "$TEMP_TAR" ]]; then
            if gunzip -k "$DOCKER_IMAGE_PATH" 2>/dev/null || gzip -d -k "$DOCKER_IMAGE_PATH" 2>/dev/null; then
                :
            else
                print_error "Failed to decompress image archive"
                exit 1
            fi
        fi
        if docker load -i "$TEMP_TAR"; then
            print_success "Docker image loaded from decompressed archive"
        else
            print_error "Failed to load Docker image"
            exit 1
        fi
    fi
fi

# Step 3: Resolve repository path (must be provided via env/.env)
if [[ -z "$REPO_PATH" ]]; then
    print_error "REPO_PATH env var is required (set it in .env or export before running)."
    exit 1
fi
REPO_PATH=$(normalize_path "$REPO_PATH")
if [[ ! -d "$REPO_PATH" ]]; then
    print_error "REPO_PATH directory does not exist: $REPO_PATH"
    exit 1
fi
if [[ ! -d "$REPO_PATH/.git" ]]; then
    print_warning "REPO_PATH is not a git repository: $REPO_PATH"
fi
print_success "Using repository path from env: $REPO_PATH"

# Step 4: Navigate to repository directory immediately so subsequent operations (volume mount, etc.) use it
print_info "Changing working directory to REPO_PATH..."
cd "$REPO_PATH"
print_success "Current working directory: $(pwd)"

# Step 5: Configuration (non-interactive)
GITHUB_OWNER="Bridge-Placement"

if [[ -z "$GITHUB_REPO" ]]; then
    # Extract repo name from REPO_PATH
    if [[ -n "$REPO_PATH" ]]; then
        GITHUB_REPO=$(basename "$REPO_PATH")
        print_info "GITHUB_REPO not set; using repo name from REPO_PATH: $GITHUB_REPO"
    else
        print_error "GITHUB_REPO env var is required (repository name within Bridge-Placement), and could not extract from REPO_PATH."
        exit 1
    fi
fi
if [[ -z "$COMPANY_TOKEN" ]]; then
    print_error "COMPANY_TOKEN env var is required."
    exit 1
fi

# Determine git user name
GIT_USER_NAME=$(git config --local --get user.name 2>/dev/null || true)
if [[ -z "$GIT_USER_NAME" ]]; then
    GIT_USER_NAME=$(git config --global --get user.name 2>/dev/null || true)
fi
if [[ -z "$GIT_USER_NAME" ]]; then
    GIT_USER_NAME=${USER:-unknown}
fi

# Sanitize (lowercase, replace spaces/invalid chars with dash, trim dashes)
sanitize() { local s="$1"; s=$(echo "$s" | tr 'A-Z' 'a-z' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'); echo "$s"; }
SANITIZED_USER=$(sanitize "$GIT_USER_NAME")
if [[ -z "$SANITIZED_USER" ]]; then SANITIZED_USER="user"; fi

RUNNER_NAME="runner-${SANITIZED_USER}-$(echo "$HOST_ID" | cut -c1-30)"

# Base labels
BASE_LABELS="self-hosted,docker"
if [[ -n "$RUNNER_LABELS" ]]; then
    # Merge custom labels ensuring no duplicate commas
    ALL_LABELS="$BASE_LABELS,$RUNNER_LABELS"
else
    ALL_LABELS="$BASE_LABELS"
fi
# Append user label if not already present
if ! echo "$ALL_LABELS" | tr ',' '\n' | grep -qx "user-$SANITIZED_USER"; then
    ALL_LABELS="$ALL_LABELS,user-$SANITIZED_USER"
fi
RUNNER_LABELS="$ALL_LABELS"

if (( ${#COMPANY_TOKEN} < 30 )); then
    print_warning "COMPANY_TOKEN length seems short; ensure scopes are correct (repo, workflow)."
fi

print_info "Configuration summary:" 
echo "  Owner (fixed): $GITHUB_OWNER"
echo "  Repository: $GITHUB_REPO"
echo "  Git user.name: $GIT_USER_NAME (sanitized: $SANITIZED_USER)"
echo "  Runner name: $RUNNER_NAME"
echo "  Labels: $RUNNER_LABELS"
echo "  Repo path: $REPO_PATH"

# Step 6: Check if container already exists (auto-remove)
CONTAINER_NAME="github-runner-$GITHUB_OWNER-$GITHUB_REPO"
if docker ps -a --format "table {{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
    print_warning "Container '$CONTAINER_NAME' already exists; removing for fresh setup." 
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
    print_success "Existing container removed"
fi

# Step 7: Run the Docker container
print_info "Starting GitHub runner container..."
echo ""
print_info "Container configuration:"
echo "  - Name: $CONTAINER_NAME"
echo "  - Repository: $GITHUB_OWNER/$GITHUB_REPO"
echo "  - Runner Name: $RUNNER_NAME"
echo "  - Labels: $RUNNER_LABELS"
echo "  - Workspace: $(pwd)"
echo ""

# Get the image name from the loaded image (assuming it's the first one)
#IMAGE_NAME=$(docker images --format "table {{.Repository}}:{{.Tag}}" | grep -v "REPOSITORY" | head -n 1)

if [ -z "$IMAGE_NAME" ]; then
    print_error "Could not determine the loaded Docker image name"
    exit 1
fi

print_info "Using Docker image: $IMAGE_NAME"

if docker run -d --name "$CONTAINER_NAME" \
    -v "$(pwd)":/workspace \
    -e REGISTRATION_MODE=repo \
    -e GITHUB_OWNER="$GITHUB_OWNER" \
    -e GITHUB_REPO="$GITHUB_REPO" \
    -e RUNNER_NAME="$RUNNER_NAME" \
    -e RUNNER_LABELS="$RUNNER_LABELS" \
    -e COMPANY_TOKEN="$COMPANY_TOKEN" \
    "$IMAGE_NAME"; then
    
        print_success "GitHub runner container started successfully!"
        echo ""
        print_info "Container details:"
        docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        print_info "To view container logs: docker logs $CONTAINER_NAME"
        print_info "To stop the container: docker stop $CONTAINER_NAME"
        print_info "To remove the container: docker rm $CONTAINER_NAME"
else
        print_error "Failed to start the GitHub runner container"
        exit 1
fi

print_success "Setup completed successfully!"
