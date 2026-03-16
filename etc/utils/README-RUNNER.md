# Self-Hosted GitHub Actions Runner Docker Setup

This Docker setup provides a self-hosted GitHub Actions runner that can work with either:
- **Organization-wide**: All repositories in an organization
- **Repository-specific**: A single repository

## Features

- 🏢 **Organization-wide or repository-specific** runner support
- 🔄 **Multi-architecture support** (x64, ARM64, ARM)
- 🐳 **Dockerized** for easy deployment and isolation new trend test checkout
- 🔄 **Auto-cleanup** and graceful shutdown
- 🏷️ **Automatic labeling** based on detected architecture test runner new test

## Quick Start

1. **Copy and configure environment file:**
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

2. **For organization-wide runners (recommended):**
   ```bash
   # .env file should have:
   COMPANY_TOKEN=ghp_your_token_here
   GITHUB_OWNER=your-organization
   REGISTRATION_MODE=org
   ```

3. **Build and run:**
   ```bash
   docker-compose up --build
   ```

## Architecture Support

### Automatic Detection
The setup automatically detects your system architecture and downloads the appropriate GitHub Actions runner binary:

- **Intel/AMD (x86_64)**: Downloads `x64` runner
- **Apple Silicon (M1/M2/M4)**: Downloads `arm64` runner  
- **ARM systems**: Downloads `arm64` or `arm` runner

### Cross-Platform Compatibility

**✅ Will work on:**
- macOS with Apple Silicon (M1/M2/M4)
- macOS with Intel processors
- Linux x86_64 systems
- Linux ARM64 systems
- Windows with WSL2 (Docker Desktop)
- Windows with Docker Desktop (requires platform override)

**⚠️ Windows Notes:**
Your current Dockerfile is Linux-based and will work on Windows machines **if**:
1. Using **Docker Desktop with WSL2 backend** (recommended)
2. Using **Windows containers** (would require a Windows-based Dockerfile)

For Windows users with Docker Desktop, the Linux containers will run in WSL2, which works perfectly.

### Platform Override

To force a specific architecture:
```bash
# For x86_64 systems
docker-compose --platform linux/amd64 up --build

# For ARM64 systems  
docker-compose --platform linux/arm64 up --build
```

## Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `COMPANY_TOKEN` | GitHub Personal Access Token | - | ✅ |
| `GITHUB_OWNER` | Organization or user name | - | ✅ |
| `GITHUB_REPO` | Repository name (repo mode only) | - | ⚠️ |
| `REGISTRATION_MODE` | `org` or `repo` | `org` | ❌ |
| `RUNNER_NAME` | Name for the runner | `docker-runner-*` | ❌ |
| `RUNNER_LABELS` | Custom labels | auto-detected | ❌ |

### GitHub PAT Permissions

**For organization runners (`REGISTRATION_MODE=org`):**
- Scope: `admin:org`
- Allows runner to work with any repository in the organization

**For repository runners (`REGISTRATION_MODE=repo`):**
- Scope: `repo` 
- Allows runner to work with the specific repository only

## Usage in Workflows

Once running, you can use the runner in your workflows:

```yaml
name: My Workflow
on: [push]

jobs:
  build:
    runs-on: self-hosted
    # or be more specific:
    # runs-on: [self-hosted, docker, linux, arm64]
    
    steps:
      - uses: actions/checkout@v4
      - name: Run commands
        run: |
          echo "Running on self-hosted runner!"
          uname -a
```

## Runner Labels

The runner automatically sets these labels:
- `self-hosted` - Always present for self-hosted runners
- `docker` - Indicates it's running in Docker
- `linux` - Operating system
- `x64` / `arm64` / `arm` - Architecture (auto-detected)

## Troubleshooting

### Check runner status
```bash
docker-compose logs -f github-runner
```

### Verify architecture detection
```bash
docker-compose exec github-runner uname -m
```

### Test GitHub API connectivity
```bash
docker-compose exec github-runner curl -H "Authorization: Bearer $COMPANY_TOKEN" \
  https://api.github.com/orgs/YOUR_ORG/actions/runners
```

### Restart runner
```bash
docker-compose restart github-runner
```

## Cleanup

To stop and remove the runner:
```bash
docker-compose down
```

The runner will automatically unregister itself from GitHub when stopped.
