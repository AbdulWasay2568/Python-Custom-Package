# Multi-Repository GitHub Actions Runner Deployment

This solution automatically deploys self-hosted GitHub Actions runners to **every repository** you have access to in your organization, with multi-architecture support.

## 🎯 What This Does

- **Discovers all repositories** in your organization that you have admin access to
- **Creates individual runners** for each repository
- **Supports multiple architectures** (AMD64, ARM64, ARM)
- **Manages multiple containers** (one per repository)
- **Provides centralized monitoring** and management

## 🚀 Quick Start

```bash
# 1. Make sure your .env file has your credentials
# GITHUB_OWNER=Bridge-Placement
# COMPANY_TOKEN=ghp_your_token_here

# 2. Deploy to all repos (uses .env automatically)
./deploy-multi-repo-runners.sh

# 3. Or deploy to specific repo only
./deploy-multi-repo-runners.sh -r Shared

# 4. Monitor all runners
./manage-runners.sh status
```

**Even Simpler - Environment Variables:**
```bash
export GITHUB_OWNER="Bridge-Placement"
export COMPANY_TOKEN="ghp_your_token_here"
./deploy-multi-repo-runners.sh
```

## 📋 Features

- ✅ **Auto-discovery** of accessible repositories
- ✅ **Multi-architecture support** (Intel, Apple Silicon, ARM)
- ✅ **Individual containers** per repository
- ✅ **Bulk management** commands
- ✅ **Health monitoring** across all runners
- ✅ **Easy scaling** up/down

## 🛠️ Architecture

```
Organization: Bridge-Placement
├── repo1/ → docker-runner-repo1 (container)
├── repo2/ → docker-runner-repo2 (container)  
├── repo3/ → docker-runner-repo3 (container)
└── ...
```

Each repository gets its own dedicated runner container with automatic platform detection.

## 📚 Available Scripts

### 1. `deploy-multi-repo-runners.sh` - Main Deployment Script

**Deploy to all accessible repositories (uses .env file):**
```bash
./deploy-multi-repo-runners.sh
```

**Deploy to specific repository only:**
```bash
./deploy-multi-repo-runners.sh -r Shared
```

**Dry run to see what would be deployed:**
```bash
./deploy-multi-repo-runners.sh --dry-run
```

**Deploy with limits and exclusions:**
```bash
# Deploy to max 5 repos, exclude certain repos
./deploy-multi-repo-runners.sh --max-repos 5 --exclude "old-repo,archived-repo"

# Deploy with custom labels
./deploy-multi-repo-runners.sh -l "gpu,production"

# Use custom .env file
./deploy-multi-repo-runners.sh -e /path/to/production.env
```

**Override .env with command line (if needed):**
```bash
./deploy-multi-repo-runners.sh -o Bridge-Placement -t ghp_xxxx
```

### 2. `manage-runners.sh` - Management & Monitoring

**Check status of all runners:**
```bash
./manage-runners.sh status
```

**Manage individual runners:**
```bash
./manage-runners.sh start repo-name     # Start specific repo runner
./manage-runners.sh stop repo-name      # Stop specific repo runner  
./manage-runners.sh logs repo-name      # View logs for specific repo
./manage-runners.sh restart repo-name   # Restart specific repo runner
```

**Bulk operations:**
```bash
./manage-runners.sh start-all    # Start all runners
./manage-runners.sh stop-all     # Stop all runners
./manage-runners.sh restart-all  # Restart all runners
./manage-runners.sh logs         # View all logs
```

**Monitoring & maintenance:**
```bash
./manage-runners.sh health       # Health check all runners
./manage-runners.sh stats        # Resource usage statistics
./manage-runners.sh list         # List configured repositories
./manage-runners.sh clean-all    # Remove all runners
```

### 3. `setup-example.sh` - Quick Setup Guide

Interactive setup script that walks you through the entire process:
```bash
export GITHUB_OWNER="Bridge-Placement"
export COMPANY_TOKEN="ghp_your_token_here"
./setup-example.sh
```

## 🎯 Example Usage Scenarios

### Scenario 1: Deploy to All Repos
```bash
# Deploy runners to every repository you have admin access to
./deploy-multi-repo-runners.sh

# Check status
./manage-runners.sh status

# Monitor health
./manage-runners.sh health
```

### Scenario 2: Selective Deployment
```bash
# Deploy only to specific repositories
./deploy-multi-repo-runners.sh -r MyApp

# Or exclude certain repos
./deploy-multi-repo-runners.sh --exclude "old-project,archived-repo"
```

### Scenario 3: Production Deployment with Limits
```bash
# Deploy to max 10 repos with production labels
./deploy-multi-repo-runners.sh \
  --max-repos 10 \
  -l "production,kubernetes,gpu"
```

## 📊 Sample Status Output

```
📊 Multi-Repository Runner Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Repository: Shared
Status: Running ✅
Container: github-runner-Shared
Platform: linux/arm64
Uptime: 2 hours
Dashboard: https://github.com/Bridge-Placement/Shared/settings/actions/runners

Repository: MyApp
Status: Running ✅
Container: github-runner-MyApp
Platform: linux/amd64
Uptime: 1 hour
Dashboard: https://github.com/Bridge-Placement/MyApp/settings/actions/runners

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📈 Summary: 2 total, 2 running, 0 stopped
```

## � Configuration

The deployment script automatically creates individual configuration files for each repository:

```bash
# Generated files per repository:
.env.repo1                    # Environment config for repo1
docker-compose.repo1.yml      # Docker compose for repo1
.env.repo2                    # Environment config for repo2
docker-compose.repo2.yml      # Docker compose for repo2
```

Each `.env` file contains:
```bash
COMPANY_TOKEN=ghp_your_token
GITHUB_OWNER=Bridge-Placement
GITHUB_REPO=repo1
REGISTRATION_MODE=repo
RUNNER_NAME=docker-runner-repo1-$(hostname)
RUNNER_LABELS=self-hosted,docker,linux
```

## 🎯 GitHub Actions Workflow Usage

In your repository workflows, use the dedicated runner:

```yaml
name: Build
on: [push, pull_request]

jobs:
  build:
    # This uses the dedicated runner for THIS specific repository
    runs-on: [self-hosted, docker, linux]
    
  build-arm64:
    # Architecture-specific targeting
    runs-on: [self-hosted, docker, linux, arm64]
    
  build-amd64:
    runs-on: [self-hosted, docker, linux, x64]
```

## 🚨 Requirements

- **Docker & Docker Compose** installed
- **GitHub PAT** with `repo` scope
- **Admin access** to target repositories
- **Sufficient resources**: ~1GB RAM and 2GB disk per repository

## 📈 Resource Planning

Each runner container uses approximately:
- **Memory**: 512MB - 1GB per container
- **CPU**: 0.5 - 1.0 cores per container  
- **Disk**: 2GB - 5GB per container

**For 10 repositories**: ~5-10GB RAM, 20-50GB disk space recommended.

## 🔍 Troubleshooting

### Check overall health:
```bash
./manage-runners.sh health
```

### View logs for problematic runner:
```bash
./manage-runners.sh logs problem-repo
```

### Restart specific runner:
```bash
./manage-runners.sh restart problem-repo
```

### Clean up and redeploy:
```bash
./manage-runners.sh clean problem-repo
./deploy-multi-repo-runners.sh -r problem-repo
```

## 🎉 Result

You'll have **dedicated self-hosted runners for every repository** you have access to in your organization, each running in its own container with multi-architecture support!

**GitHub Dashboard Links** (automatically generated):
- `https://github.com/Bridge-Placement/repo1/settings/actions/runners`
- `https://github.com/Bridge-Placement/repo2/settings/actions/runners`
- etc.

---

**Perfect for organizations that want isolated runners per repository with centralized management!**
