# NAIS Reusable GitHub Actions

A collection of reusable GitHub Actions workflows for NAIS projects.

## Build and Deploy with mise to Fasit

A comprehensive, opinionated reusable workflow for projects that use [mise](https://mise.jdx.dev/) for task management. While originally designed for Go projects, this workflow is language-agnostic and can be used with any mise-managed project. It handles quality checks, building, Docker image creation, Helm chart publishing, and deployment to Fasit.

### Features

- ✅ **Parallel Quality Checks**: Runs quality checks in parallel using mise tasks (configurable per project)
- 🏗️ **Build Management**: Automated builds with mise
- 🐳 **Docker Support**: Build and push Docker images to Google Artifact Registry
- ⎈ **Helm Chart Support**: Package and publish Helm charts
- 🚀 **Deployment**: Optional deployment to Fasit
- 🏷️ **Version Tagging**: Automatic git tag creation
- 💾 **Caching**: Optimized build caching for faster runs
- 🔒 **Security**: Workload identity federation for GCP authentication

### Prerequisites

Your project must have a `mise.toml` file defining at minimum:
- A `version` task (generates a version string)
- A `build` task (builds your project)
- Optional: quality check tasks (lint, test, etc.)

**Minimal Example:**

```toml
[tasks.version]
description = "Generate version string"
run = 'echo "$(date +%Y%m%d)-$(git rev-parse --short HEAD)"'

[tasks.build]
description = "Build the application"
run = "go build -o bin/app ./cmd/app"
```

**With Quality Checks (Recommended):**

```toml
[tasks.version]
run = 'echo "$(date +%Y%m%d)-$(git rev-parse --short HEAD)"'

[tasks.lint]
run = "golangci-lint run"

[tasks.test]
run = "go test -race ./..."

[tasks.build]
run = "go build -o bin/app ./cmd/app"
```

Then configure the workflow to run your specific tasks:

```yaml
with:
  mise-tasks: '["lint", "test"]'  # Only run the tasks you've defined
```

### Basic Usage

Create a workflow file in your repository (e.g., `.github/workflows/build.yaml`):

```yaml
name: Build and Deploy

on:
  push:
    branches:
      - main
  pull_request:

permissions:
  contents: read
  id-token: write

jobs:
  build:
    uses: nais/actions/.github/workflows/mise-build-deploy-fasit.yaml@abc123def456 # ratchet:nais/actions/.github/workflows/mise-build-deploy-fasit.yaml@main
    secrets:
      NAIS_IO_WORKLOAD_IDENTITY_PROVIDER: ${{ secrets.NAIS_IO_WORKLOAD_IDENTITY_PROVIDER }}
```

> **Note**: Replace `abc123def456` with the actual commit SHA you want to pin to. Using [Ratchet](https://github.com/sethvargo/ratchet) will automatically manage these SHA pins for you.

### Advanced Usage

#### Custom mise Tasks

```yaml
jobs:
  build:
    uses: nais/actions/.github/workflows/mise-build-deploy-fasit.yaml@main
    with:
      mise-tasks: '["tidy-check", "fmt-check", "lint", "vet", "test"]'
      mise-task-build: 'build-production'
      mise-task-version: 'semantic-version'
    secrets:
      NAIS_IO_WORKLOAD_IDENTITY_PROVIDER: ${{ secrets.NAIS_IO_WORKLOAD_IDENTITY_PROVIDER }}
```

#### With Helm Chart

```yaml
jobs:
  build:
    uses: nais/actions/.github/workflows/mise-build-deploy-fasit.yaml@main
    with:
      builds-chart: true
      chart-path: './charts'
      deploys-to-fasit: true
    secrets:
      NAIS_IO_WORKLOAD_IDENTITY_PROVIDER: ${{ secrets.NAIS_IO_WORKLOAD_IDENTITY_PROVIDER }}
```

#### Custom Docker Configuration

```yaml
jobs:
  build:
    uses: nais/actions/.github/workflows/mise-build-deploy-fasit.yaml@main
    with:
      dockerfile-path: './build/Dockerfile'
      docker-context: './build'
      artifact-registry: 'europe-west1-docker.pkg.dev'
      artifact-repo: 'my-project/my-repo'
    secrets:
      NAIS_IO_WORKLOAD_IDENTITY_PROVIDER: ${{ secrets.NAIS_IO_WORKLOAD_IDENTITY_PROVIDER }}
```

#### With Git Tagging

```yaml
jobs:
  build:
    uses: nais/actions/.github/workflows/mise-build-deploy-fasit.yaml@main
    with:
      creates-git-tag: true
    permissions:
      contents: write
      id-token: write
    secrets:
      NAIS_IO_WORKLOAD_IDENTITY_PROVIDER: ${{ secrets.NAIS_IO_WORKLOAD_IDENTITY_PROVIDER }}
```

### Inputs

| Input                | Description                                                    | Required | Default                                                                                                       |
| -------------------- | -------------------------------------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------- |
| `mise-task-version`  | mise task name for version generation                          | No       | `version`                                                                                                     |
| `mise-tasks`         | JSON array of mise tasks to run in parallel for quality checks | No       | `["tidy-check", "fmt-check", "lint", "vet", "check", "test-race"]` (Go defaults - customize for your project) |
| `mise-task-build`    | mise task name for building                                    | No       | `build`                                                                                                       |
| `builds-docker`      | Build and push Docker image                                    | No       | `true`                                                                                                        |
| `dockerfile-path`    | Path to Dockerfile                                             | No       | `./Dockerfile`                                                                                                |
| `docker-context`     | Docker build context                                           | No       | `.`                                                                                                           |
| `builds-chart`       | Build and push Helm chart                                      | No       | `false`                                                                                                       |
| `chart-path`         | Path to Helm chart directory                                   | No       | `./charts`                                                                                                    |
| `deploys-to-fasit`   | Deploy to Fasit                                                | No       | `false`                                                                                                       |
| `creates-git-tag`    | Create and push git tag                                        | No       | `false`                                                                                                       |
| `artifact-registry`  | Docker registry for artifacts                                  | No       | `europe-north1-docker.pkg.dev`                                                                                |
| `artifact-repo`      | Docker repository name                                         | No       | `nais-io/nais/images`                                                                                         |
| `chart-repo`         | Helm chart repository name                                     | No       | `nais-io/nais/charts`                                                                                         |
| `runner-size`        | GitHub Actions runner size                                     | No       | `ubuntu-latest`                                                                                               |
| `runner-size-docker` | GitHub Actions runner size for Docker builds                   | No       | `ubuntu-latest-16-cores`                                                                                      |
| `helm-version`       | Helm version to use                                            | No       | `v3.16.3`                                                                                                     |

### Secrets

| Secret                               | Description                                       | Required |
| ------------------------------------ | ------------------------------------------------- | -------- |
| `NAIS_IO_WORKLOAD_IDENTITY_PROVIDER` | GCP Workload Identity Provider for authentication | No*      |

\* Required if pushing Docker images or Helm charts to Google Artifact Registry

### Outputs

| Output    | Description                             |
| --------- | --------------------------------------- |
| `version` | Generated version string from mise task |
| `name`    | Repository name                         |
| `image`   | Full Docker image reference with tag    |

### Example: Using Outputs

```yaml
jobs:
  build:
    uses: nais/actions/.github/workflows/mise-build-deploy-fasit.yaml@main
    secrets:
      NAIS_IO_WORKLOAD_IDENTITY_PROVIDER: ${{ secrets.NAIS_IO_WORKLOAD_IDENTITY_PROVIDER }}

  deploy-custom:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to custom environment
        run: |
          echo "Deploying ${{ needs.build.outputs.image }}"
          echo "Version: ${{ needs.build.outputs.version }}"
```

### Required Permissions

The calling workflow must have appropriate permissions:

```yaml
permissions:
  contents: read          # Required for checkout
  id-token: write         # Required for GCP authentication
  contents: write         # Required only if creates-git-tag: true
```

### GCP Service Account Setup

For Docker and Helm chart pushing, ensure you have:

1. A GCP service account named `gh-{repository-name}@nais-io.iam.gserviceaccount.com`
2. Workload Identity Federation configured
3. The service account must have permissions to push to Artifact Registry

### Workflow Jobs

The reusable workflow consists of the following jobs:

1. **meta**: Generates version and repository metadata
2. **lint**: Runs quality checks in parallel (configurable via `mise-tasks`)
3. **build**: Builds the Go application
4. **docker**: Builds and pushes Docker image (if `builds-docker: true`)
5. **chart**: Packages and pushes Helm chart (if `builds-chart: true`)
6. **rollout**: Deploys to Fasit (if `deploys-to-fasit: true`)
7. **tag**: Creates git tag (if `creates-git-tag: true`)

### Best Practices

1. **Pin to a specific commit SHA**: For maximum security and reproducibility, pin to a specific commit SHA. We recommend using [Ratchet](https://github.com/sethvargo/ratchet) to automatically update SHA pins:

   ```yaml
   uses: nais/actions/.github/workflows/mise-build-deploy-fasit.yaml@abc123def456 # ratchet:nais/actions/.github/workflows/mise-build-deploy-fasit.yaml@main
   ```

   Ratchet will automatically update the SHA while keeping the comment as a human-readable reference.

2. **Use minimal permissions**: Only grant the permissions your workflow needs:
   ```yaml
   permissions:
     contents: read
     id-token: write
   ```

3. **Customize mise tasks**: Adapt the quality checks to your project's needs:
   ```yaml
   with:
     mise-tasks: '["tidy-check", "fmt-check", "lint", "test"]'
   ```

4. **Skip Docker builds for PRs**: The workflow automatically skips pushing to production on pull requests

5. **Use Ratchet or Dependabot**: Keep your workflow reference updated:
   - **Ratchet**: Automatically updates SHA pins in your workflow files
   - **Dependabot**: Sends PRs for GitHub Actions updates (works with SHA pins)

### Troubleshooting

#### Authentication Failures

If you see authentication errors:
- Verify the `NAIS_IO_WORKLOAD_IDENTITY_PROVIDER` secret is set
- Confirm the GCP service account exists and has the correct name
- Check that Workload Identity Federation is configured

#### mise Task Not Found

If a mise task is missing:
- Ensure all referenced tasks are defined in your `mise.toml`
- Check task names match exactly (case-sensitive)
- Run `mise tasks` locally to list available tasks

#### Docker Build Fails

If Docker builds fail:
- Verify `dockerfile-path` points to a valid Dockerfile
- Check that `docker-context` contains all necessary files
- Review Docker build logs in the Actions run

### Contributing

Contributions are welcome! Please:
1. Open an issue to discuss major changes
2. Follow existing patterns and conventions
3. Update documentation as needed
4. Test changes thoroughly

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues and questions:
- 🐛 [Report a bug](https://github.com/nais/actions/issues)
- 💡 [Request a feature](https://github.com/nais/actions/issues)
- 💬 [Ask in discussions](https://github.com/nais/actions/discussions)
