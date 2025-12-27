# NAIS Reusable GitHub Actions

Reusable workflows for NAIS projects using [mise](https://mise.jdx.dev/) for task management.

## Table of Contents

- [⎈ mise-build-deploy-fasit.yaml](#-mise-build-deploy-fasityaml) - Fasit with Helm charts
- [🚀 mise-build-deploy-nais.yaml](#-mise-build-deploy-naisyaml) - Standard NAIS deployment
- [🤖 dependabot-auto-merge.yaml](#-dependabot-auto-mergeyaml) - Auto-merge Dependabot PRs
- [Common Features](#common-features) · [Prerequisites](#prerequisites) · [Best Practices](#best-practices)

---

## Available Workflows

### ⎈ mise-build-deploy-fasit.yaml

Fasit platform deployment workflow with Helm chart support.

```yaml
uses: nais/actions/.github/workflows/mise-build-deploy-fasit.yaml@abc123 # ratchet:nais/actions/.github/workflows/mise-build-deploy-fasit.yaml@main
with:
  builds-chart: true
  deploys-to-fasit: true
secrets:
  NAIS_IO_WORKLOAD_IDENTITY_PROVIDER: ${{ secrets.NAIS_IO_WORKLOAD_IDENTITY_PROVIDER }}
```

**Features:**

- ✅ Helm chart packaging and publishing
- ✅ Fasit deployment support
- ✅ Single-cluster deployment model

[View full documentation](#mise-build-deploy-fasityaml-1)

---

### 🚀 mise-build-deploy-nais.yaml

Standard NAIS deployment workflow using `nais/deploy`.

```yaml
uses: nais/actions/.github/workflows/mise-build-deploy-nais.yaml@abc123 # ratchet:nais/actions/.github/workflows/mise-build-deploy-nais.yaml@main
with:
  deploys-to-nais: true
  nais-team: my-team
  nais-clusters: '["dev-gcp", "prod-gcp"]'
secrets:
  NAIS_IO_WORKLOAD_IDENTITY_PROVIDER: ${{ secrets.NAIS_IO_WORKLOAD_IDENTITY_PROVIDER }}
```

**Features:**

- ✅ Multi-cluster deployment (dev-gcp, prod-gcp, etc.)
- ✅ Optional PR deployments to dev
- ✅ Uses `.nais/app.yaml` manifests

[View full documentation](#mise-build-deploy-naisyaml-1)

---

### 🤖 dependabot-auto-merge.yaml

Automatically merge non-major Dependabot pull requests.

```yaml
uses: nais/actions/.github/workflows/dependabot-auto-merge.yaml@abc123 # ratchet:nais/actions/.github/workflows/dependabot-auto-merge.yaml@main
secrets:
  DEPENDABOT_AUTO_MERGE_APP_ID: ${{ secrets.DEPENDABOT_AUTO_MERGE_APP_ID }}
  DEPENDABOT_AUTO_MERGE_APP_SECRET: ${{ secrets.DEPENDABOT_AUTO_MERGE_APP_SECRET }}
```

**Features:**

- ✅ Auto-merges patch and minor version updates
- ✅ Skips major version updates (manual review required)
- ✅ Uses squash merge strategy
- ✅ Requires GitHub App authentication

**Setup:**

1. **GitHub App**: Install the existing NAIS Dependabot auto-merge GitHub App in your repository (contact your GitHub org admin if needed)
2. **Repository Secrets**: Ensure `DEPENDABOT_AUTO_MERGE_APP_ID` and `DEPENDABOT_AUTO_MERGE_APP_SECRET` are available (usually set at org level)
3. **Workflow Permissions**: The calling workflow needs `pull-requests: write` permission
4. Create `.github/workflows/dependabot.yaml`:

```yaml
name: Dependabot
on: pull_request

permissions:
  pull-requests: write  # Required for the GitHub App to merge PRs

jobs:
  auto-merge:
    uses: nais/actions/.github/workflows/dependabot-auto-merge.yaml@abc123 # ratchet:nais/actions/.github/workflows/dependabot-auto-merge.yaml@main
    secrets:
      DEPENDABOT_AUTO_MERGE_APP_ID: ${{ secrets.DEPENDABOT_AUTO_MERGE_APP_ID }}
      DEPENDABOT_AUTO_MERGE_APP_SECRET: ${{ secrets.DEPENDABOT_AUTO_MERGE_APP_SECRET }}
```

---

## Common Features

Both workflows share these capabilities:

- 🔧 **Parallel Quality Checks**: Run mise tasks in parallel (lint, test, etc.)
- 🏗️ **Build Management**: Execute your mise build task
- 🐳 **Docker**: Build and push to Google Artifact Registry
- 🏷️ **Git Tags**: Optional automatic tagging
- 💾 **Caching**: Optimized build caching
- 🔒 **Security**: GCP Workload Identity Federation

## Prerequisites

Both workflows require a `mise.toml` with minimum tasks:

```toml
[tasks.version]
run = 'echo "$(date +%Y%m%d)-$(git rev-parse --short HEAD)"'

[tasks.build]
run = "go build -o bin/app ./cmd/app"
```

**Recommended - add quality checks:**

```toml
[tasks.lint]
run = "golangci-lint run"

[tasks.test]
run = "go test -race ./..."
```

Configure which tasks to run:

```yaml
with:
  mise-tasks: '["lint", "test"]'
```

---

## mise-build-deploy-fasit.yaml

Deploy to Fasit with Helm chart support.

### Quick Start

```yaml
name: Build and Deploy
on:
  push:
    branches: [main]

permissions:
  contents: read
  id-token: write

jobs:
  deploy:
    uses: nais/actions/.github/workflows/mise-build-deploy-fasit.yaml@abc123 # ratchet:nais/actions/.github/workflows/mise-build-deploy-fasit.yaml@main
    with:
      builds-chart: true
      deploys-to-fasit: true
      chart-path: './charts'
      mise-tasks: '["lint", "test"]'
    secrets:
      NAIS_IO_WORKLOAD_IDENTITY_PROVIDER: ${{ secrets.NAIS_IO_WORKLOAD_IDENTITY_PROVIDER }}
```

### Key Inputs

| Input               | Description                                      | Default                                                            |
| ------------------- | ------------------------------------------------ | ------------------------------------------------------------------ |
| `builds-chart`      | Build Helm chart                                 | `false`                                                            |
| `deploys-to-fasit`  | Deploy to Fasit                                  | `false`                                                            |
| `chart-path`        | Helm chart directory                             | `./charts`                                                         |
| `chart-repo`        | Chart repository                                 | `nais-io/nais/charts`                                              |
| `working-directory` | Working directory for monorepo support           | `.`                                                                |
| `mise-setup-tasks`  | Setup tasks to run before checks (e.g., install) | `[]`                                                               |
| `mise-tasks`        | Quality check tasks                              | `["tidy-check", "fmt-check", "lint", "vet", "check", "test-race"]` |
| `mise-task-build`   | Build task name                                  | `build`                                                            |
| `mise-task-version` | Version task name                                | `version`                                                          |

### Required Setup

1. **Helm Chart**: Create chart in `./charts/{repo-name}/`
2. **GCP Service Account**: `gh-{repo-name}@nais-io.iam.gserviceaccount.com`
3. **Workload Identity**: Configure federation

---

## mise-build-deploy-nais.yaml

Deploy to NAIS clusters using standard `nais/deploy`.

### Quick Start

```yaml
name: Build and Deploy
on:
  push:
    branches: [main]
  pull_request:

permissions:
  contents: read
  id-token: write

jobs:
  deploy:
    uses: nais/actions/.github/workflows/mise-build-deploy-nais.yaml@abc123 # ratchet:nais/actions/.github/workflows/mise-build-deploy-nais.yaml@main
    with:
      deploys-to-nais: true
      nais-team: my-team
      nais-clusters: '["dev-gcp", "prod-gcp"]'
      mise-tasks: '["lint", "test"]'
    secrets:
      NAIS_IO_WORKLOAD_IDENTITY_PROVIDER: ${{ secrets.NAIS_IO_WORKLOAD_IDENTITY_PROVIDER }}
```

### Key Inputs

| Input               | Description                                        | Default                                                            |
| ------------------- | -------------------------------------------------- | ------------------------------------------------------------------ |
| `deploys-to-nais`   | Enable NAIS deployment                             | `false`                                                            |
| `nais-clusters`     | JSON array of clusters                             | `["dev-gcp"]`                                                      |
| `nais-team`         | Team name                                          | `nais`                                                             |
| `nais-resource`     | Path to app manifest                               | `.nais/app.yaml`                                                   |
| `nais-vars`         | Path to cluster vars (use `{cluster}` placeholder) | `.nais/{cluster}.yaml`                                             |
| `deploy-pr-to-dev`  | Deploy PRs to dev                                  | `false`                                                            |
| `working-directory` | Working directory for monorepo support             | `.`                                                                |
| `mise-setup-tasks`  | Setup tasks to run before checks (e.g., install)   | `[]`                                                               |
| `mise-tasks`        | Quality check tasks                                | `["tidy-check", "fmt-check", "lint", "vet", "check", "test-race"]` |
| `mise-task-build`   | Build task name                                    | `build`                                                            |
| `mise-task-version` | Version task name                                  | `version`                                                          |

### Required Setup

1. **NAIS Manifests**: Create `.nais/app.yaml` and cluster-specific vars
   - For multi-cluster: `.nais/dev-gcp.yaml`, `.nais/prod-gcp.yaml`, etc.
   - The `{cluster}` placeholder in `nais-vars` is automatically replaced with each cluster name
2. **GCP Service Account**: `gh-{repo-name}@nais-io.iam.gserviceaccount.com`
3. **Workload Identity**: Configure federation

### Examples

**With PR deployments:**

```yaml
with:
  deploys-to-nais: true
  deploy-pr-to-dev: true
  nais-team: my-team
```

**Custom manifests and vars pattern:**

```yaml
with:
  deploys-to-nais: true
  nais-resource: '.nais/nais.yaml'
  nais-vars: '.nais/vars-{cluster}.yaml'  # Becomes .nais/vars-dev-gcp.yaml, .nais/vars-prod-gcp.yaml, etc.
```

**Same vars file for all clusters:**

```yaml
with:
  deploys-to-nais: true
  nais-vars: '.nais/common-vars.yaml'  # No {cluster} placeholder = same file for all
```

---

## Common Inputs

Both workflows share these inputs:

| Input                | Description                                            | Default                        |
| -------------------- | ------------------------------------------------------ | ------------------------------ |
| `builds-docker`      | Build Docker image                                     | `true`                         |
| `dockerfile-path`    | Path to Dockerfile                                     | `./Dockerfile`                 |
| `docker-context`     | Build context                                          | `.`                            |
| `creates-git-tag`    | Create git tag (requires `contents: write` permission) | `false`                        |
| `artifact-registry`  | Registry URL                                           | `europe-north1-docker.pkg.dev` |
| `artifact-repo`      | Repository path                                        | `nais-io/nais/images`          |
| `runner-size`        | Runner size                                            | `ubuntu-latest`                |
| `runner-size-docker` | Docker runner size                                     | `ubuntu-latest`                |
| `working-directory`  | Working directory for monorepo support                 | `.`                            |

## Common Outputs

| Output    | Description                   |
| --------- | ----------------------------- |
| `version` | Generated version string      |
| `name`    | Repository name               |
| `image`   | Full image reference with tag |

---

## Monorepo Support

Both workflows support monorepo setups via the `working-directory` input. This allows you to run all mise tasks, builds, and deployments from within a specific subdirectory:

```yaml
jobs:
  service-a:
    uses: nais/actions/.github/workflows/mise-build-deploy-nais.yaml@abc123 # ratchet:nais/actions/.github/workflows/mise-build-deploy-nais.yaml@main
    with:
      working-directory: 'apps/service-a'
      deploys-to-nais: true
      nais-team: my-team
    secrets:
      NAIS_IO_WORKLOAD_IDENTITY_PROVIDER: ${{ secrets.NAIS_IO_WORKLOAD_IDENTITY_PROVIDER }}

  service-b:
    uses: nais/actions/.github/workflows/mise-build-deploy-fasit.yaml@abc123 # ratchet:nais/actions/.github/workflows/mise-build-deploy-fasit.yaml@main
    with:
      working-directory: 'apps/service-b'
      builds-chart: true
      deploys-to-fasit: true
    secrets:
      NAIS_IO_WORKLOAD_IDENTITY_PROVIDER: ${{ secrets.NAIS_IO_WORKLOAD_IDENTITY_PROVIDER }}
```

**Monorepo Structure Example:**

```
.
├── apps/
│   ├── service-a/
│   │   ├── mise.toml
│   │   ├── Dockerfile
│   │   └── .nais/
│   │       ├── app.yaml
│   │       └── dev-gcp.yaml
│   └── service-b/
│       ├── mise.toml
│       ├── Dockerfile
│       └── charts/
│           └── service-b/
└── .github/
    └── workflows/
        └── build.yaml
```

**Important:** When using `working-directory`:
- The `mise.toml` must be in the working directory
- Docker paths (`dockerfile-path`, `docker-context`) are relative to the working directory
- NAIS manifests and Helm charts should be in the working directory
- Each service in the monorepo should have its own `mise.toml`

## Best Practices

1. **Pin to commit SHA**: Use Ratchet for automatic SHA management

   ```yaml
   uses: nais/actions/.github/workflows/mise-build-deploy-nais.yaml@abc123 # ratchet:nais/actions/.github/workflows/mise-build-deploy-nais.yaml@main
   ```

2. **Minimal permissions**:

   ```yaml
   permissions:
     contents: read
     id-token: write
   ```

3. **Customize mise tasks**: Only run what you need

   ```yaml
   with:
     mise-tasks: '["lint", "test"]'
   ```

4. **Use Ratchet or Dependabot**: Keep workflow references updated

5. **Monorepo best practices**:
   - Keep each service's configuration in its own directory
   - Use path filters to trigger workflows only when specific services change
   - Consider using a matrix strategy for multiple services with similar configurations

## Troubleshooting

**Authentication failures:**

- Verify `NAIS_IO_WORKLOAD_IDENTITY_PROVIDER` secret exists
- Confirm GCP service account name matches pattern
- Check Workload Identity Federation configuration

**Missing mise tasks:**

- Ensure all tasks in `mise-tasks` are defined in `mise.toml`
- Run `mise tasks` locally to verify

**Docker build failures:**

- Verify `dockerfile-path` is correct
- Check `docker-context` contains required files

## Support

- 🐛 [Report a bug](https://github.com/nais/actions/issues)
- 💡 [Request a feature](https://github.com/nais/actions/issues)
- 💬 [Discussions](https://github.com/nais/actions/discussions)

## License

MIT License - see [LICENSE](LICENSE) file.
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

**Multi-language Example (Go + TypeScript):**

```toml
[tasks.version]
run = 'echo "$(date +%Y%m%d)-$(git rev-parse --short HEAD)"'

# Setup tasks - run before checks
[tasks."install:ts"]
run = "pnpm install --frozen-lockfile"

# Quality checks
[tasks."lint:go"]
run = "golangci-lint run"

[tasks."lint:ts"]
run = "pnpm run lint"

[tasks."test:go"]
run = "go test ./..."

[tasks."test:ts"]
run = "pnpm run test"

[tasks.build]
run = "go build -o bin/app ./cmd/app && pnpm run build"
```

Then configure the workflow:

```yaml
with:
  mise-setup-tasks: '["install:ts"]'  # Runs first
  mise-tasks: '["lint:go", "lint:ts", "test:go", "test:ts"]'  # Run in parallel
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
| `runner-size-docker` | GitHub Actions runner size for Docker builds                   | No       | `ubuntu-latest`                                                                                               |
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
  contents: read          # Required for checkout (use 'write' if creates-git-tag: true)
  id-token: write         # Required for GCP authentication
```

**Note:** If using `creates-git-tag: true`, you must set `contents: write` instead of `contents: read`.

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
     contents: read          # or 'write' if creates-git-tag: true
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
