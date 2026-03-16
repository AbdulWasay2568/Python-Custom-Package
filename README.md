# GitHub Self-Hosted Runner with Docker

This setup provides a containerized GitHub Actions self-hosted runner that can be configured to work with any GitHub organization or repository.

## Features

- **Flexible Registration**: Supports both organization-level and repository-level runner registration
- **Multi-Architecture**: Works on both ARM64 (Apple Silicon) and AMD64 (Intel/AMD) platforms
- **Auto-Configuration**: Automatically handles GitHub API authentication and runner registration
- **Git Credentials**: Pre-configures Git with your GitHub token for seamless repository access
- **Persistent Workspace**: Mounts your local directory as the runner workspace

## Quick Start

### 1. Create Environment Configuration

Copy the example environment file and configure it for your needs:

```bash
cp .env.example .env  
```

Edit `.env` with your GitHub configuration:

```bash
# Required: Your GitHub Personal Access Token
COMPANY_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Required: GitHub organization name
GITHUB_OWNER=Bridge-Placement

# Optional: Repository name (only needed for repo mode)
GITHUB_REPO=your-repo-name

# Registration mode: 'org' or 'repo'
REGISTRATION_MODE=org
```

### 2. GitHub Personal Access Token Setup

Create a GitHub Personal Access Token with the appropriate permissions:

#### For Organization-Level Runners (Recommended)
- Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
- Create a token with `admin:org` scope
- This allows the runner to register at the organization level and be available to all repositories

#### For Repository-Level Runners
- Create a token with `repo` scope
- You must have admin access to the specific repository
- The runner will only be available to that specific repository

### 3. Build and Run

Start the runner using Docker Compose:

```bash
# Build the image
docker-compose build

# Start the runner new
docker-compose up -d

# View logs
docker-compose logs -f
```

### 4. Verify Registration

Check that your runner appears in GitHub:

- **For Organization**: Go to `https://github.com/organizations/Bridge-Placement/settings/actions/runners`
- **For Repository**: Go to `https://github.com/Bridge-Placement/your-repo/settings/actions/runners`

## Configuration Options

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `COMPANY_TOKEN` | Yes | - | GitHub Personal Access Token |
| `GITHUB_OWNER` | Yes | - | GitHub organization or username |
| `GITHUB_REPO` | Conditional | - | Repository name (required for repo mode) |
| `REGISTRATION_MODE` | No | `repo` | Registration mode: `org` or `repo` |
| `RUNNER_NAME` | No | `docker-runner` | Name of the runner |
| `RUNNER_WORKDIR` | No | `/workspace` | Working directory inside container |
| `RUNNER_LABELS` | No | `self-hosted,docker` | Comma-separated labels for the runner |

### Platform Configuration

The docker-compose.yml file is configured for ARM64 by default (Apple Silicon). For Intel/AMD systems, change:

```yaml
platform: linux/amd64  # Change from linux/arm64
```

And update the runner labels:

```yaml
environment:
  - RUNNER_LABELS=self-hosted,docker,linux,amd64
```

## Usage Examples

### Organization-Level Runner (Recommended for Bridge-Placement)

This configuration makes the runner available to all repositories in the organization:

```bash
COMPANY_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
GITHUB_OWNER=Bridge-Placement
REGISTRATION_MODE=org
```

### Repository-Specific Runner

This configuration restricts the runner to a specific repository:

```bash
COMPANY_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
GITHUB_OWNER=Bridge-Placement
GITHUB_REPO=specific-repository
REGISTRATION_MODE=repo
```

### Using the Runner in Workflows

In your GitHub Actions workflows, target your self-hosted runner:

```yaml
name: CI
on: [push, pull_request]

jobs:
  build:
    runs-on: [self-hosted, docker]  # or use specific labels
    steps:
      - uses: actions/checkout@v4
      - name: Run build
        run: |
          # Your build commands here
          echo "Running on self-hosted runner!"
```

## Troubleshooting

### Check Runner Status

```bash
# View real-time logs
docker-compose logs -f github-runner

# Check if container is running
docker-compose ps
```

### Common Issues

1. **Authentication Failed**: Verify your GitHub PAT has the correct scopes
2. **Runner Not Appearing**: Check that the organization/repository settings allow self-hosted runners
3. **Permission Denied**: Ensure your PAT has admin access to the target organization/repository

### Clean Restart

To completely reset the runner:

```bash
# Stop and remove containers
docker-compose down

# Remove old runner registration (optional)
docker-compose run --rm github-runner ./config.sh remove --token $COMPANY_TOKEN

# Start fresh
docker-compose up -d
```

## Security Considerations

- Store your GitHub PAT securely and rotate it regularly
- Consider using organization-level runners for better security isolation
- Monitor runner activity in your GitHub organization/repository settings
- The runner has sudo access within the container for installing dependencies

## Docker Access (Optional)

If your workflows need to build Docker images or run Docker commands, uncomment this line in `docker-compose.yml`:

```yaml
volumes:
  - ..:/workspace                 # Mounts parent directory (Git repo root)
  - /var/run/docker.sock:/var/run/docker.sock  # Enable Docker-in-Docker
```

**Security Warning**: This gives the runner full access to your host's Docker daemon.

## Important Notes

- The `docker-compose.yml` file is located in the `bin/` directory
- The volume mapping `..:/workspace` mounts the parent directory (the Git repository root) to `/workspace` in the container
- This ensures that GitHub Actions workflows have access to the entire Git repository, not just the `bin/` folder
