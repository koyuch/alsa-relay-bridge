# CI/CD Pipeline Documentation

This document describes the automated build and release pipeline for the ALSA Relay Bridge project.

## Overview

The project uses GitHub Actions for continuous integration and automated releases. The pipeline consists of two main workflows:

1. **Test and Validate** ([`.github/workflows/test.yml`](.github/workflows/test.yml:1)) - Runs on every push and pull request
2. **Build and Release** ([`.github/workflows/build-release.yml`](.github/workflows/build-release.yml:1)) - Runs on version tags

## Workflows

### 1. Test and Validate Workflow

**Triggers:**
- Push to `main`, `master`, or `develop` branches
- Pull requests to these branches

**Jobs:**

#### test-build
- Tests Python code across multiple versions (3.9, 3.10, 3.11, 3.12, 3.13)
- Installs system dependencies
- Runs linting with flake8
- Performs type checking with mypy
- Validates Python syntax

#### test-package-build
- Builds the Debian package
- Runs lintian validation
- Verifies package contents

#### shellcheck
- Validates all shell scripts
- Checks bash scripts for common issues

### 2. Build and Release Workflow

**Triggers:**
- Git tags matching `v*.*.*` (e.g., `v1.0.0`)
- Manual workflow dispatch

**Jobs:**

#### build-deb
- Builds the Debian package
- Extracts version from git tag
- Updates changelog automatically
- Creates GitHub Release
- Attaches `.deb` package to release

#### lint-and-validate
- Runs code quality checks
- Validates package structure
- Checks shell scripts

## Creating a Release

### Automated Release (Recommended)

1. **Update version files:**
```bash
echo "1.0.1" > VERSION
dch -v 1.0.1 "Release notes"
git add VERSION debian/changelog
git commit -m "Bump version to 1.0.1"
git push origin main
```

2. **Create and push tag:**
```bash
git tag -a v1.0.1 -m "Release version 1.0.1"
git push origin v1.0.1
```

3. **Wait for automation:**
- GitHub Actions builds the package
- Creates a release on GitHub
- Attaches the `.deb` file

### Manual Workflow Trigger

You can also trigger the build manually from GitHub:

1. Go to **Actions** tab
2. Select **Build and Release** workflow
3. Click **Run workflow**
4. Select branch and run

## Workflow Status Badges

Add these badges to your README:

```markdown
![Build Status](https://github.com/koyuch/alsa-relay-bridge/workflows/Test%20and%20Validate/badge.svg)
![Release](https://github.com/koyuch/alsa-relay-bridge/workflows/Build%20and%20Release/badge.svg)
```

## Build Artifacts

### Test Workflow
- Builds are validated but not saved
- Linting results are shown in logs

### Release Workflow
- `.deb` package is uploaded as artifact (30-day retention)
- Package is attached to GitHub Release (permanent)
- Build info and changes files are also saved

## Environment Requirements

### Build Environment
- Ubuntu latest (GitHub-hosted runner)
- Python 3.9+
- Debian build tools (debhelper, dpkg-dev)

### Dependencies Installed
- `debhelper` - Debian packaging helper
- `dpkg-dev` - Debian package development tools
- `build-essential` - Build tools
- `lintian` - Debian package validator
- `shellcheck` - Shell script analyzer
- `flake8` - Python linter
- `mypy` - Python type checker

## Secrets and Permissions

### Required Permissions
- `GITHUB_TOKEN` - Automatically provided by GitHub Actions
  - Used for creating releases
  - No manual configuration needed

### Optional Secrets
None required for basic operation.

## Troubleshooting

### Build Fails on Tag Push

**Check:**
1. Version format in tag (must be `v*.*.*`)
2. Debian changelog syntax
3. File permissions (scripts must be executable)

**View logs:**
- Go to Actions tab
- Click on failed workflow
- Review job logs

### Package Validation Fails

**Common issues:**
1. Lintian warnings - Usually safe to ignore
2. Missing dependencies in `debian/control`
3. Incorrect file permissions

**Fix:**
```bash
# Test locally first
./build-deb.sh
lintian ../*.deb
```

### Release Not Created

**Verify:**
1. Tag pushed to GitHub: `git ls-remote --tags origin`
2. Workflow triggered: Check Actions tab
3. Build succeeded: Review workflow logs

## Local Testing

Test the CI pipeline locally before pushing:

```bash
# Install dependencies
sudo apt install debhelper dpkg-dev build-essential lintian shellcheck
pip install flake8 mypy

# Run linting
flake8 relay_volume.py --max-line-length=100
mypy relay_volume.py --ignore-missing-imports
shellcheck build-deb.sh install.sh uninstall.sh

# Build package
./build-deb.sh

# Validate package
lintian ../*.deb
```

## Customization

### Modify Build Matrix

Edit [`.github/workflows/test.yml`](.github/workflows/test.yml:1):

```yaml
strategy:
  matrix:
    python-version: ['3.9', '3.10', '3.11', '3.12']
```

### Change Release Triggers

Edit [`.github/workflows/build-release.yml`](.github/workflows/build-release.yml:1):

```yaml
on:
  push:
    tags:
      - 'v*.*.*'      # Version tags
      - 'release-*'   # Alternative pattern
```

### Add Deployment Steps

Add to the release workflow:

```yaml
- name: Deploy to APT repository
  run: |
    # Your deployment commands
```

## Best Practices

1. **Always test locally** before pushing tags
2. **Use semantic versioning** for tags
3. **Update changelog** before creating releases
4. **Review workflow logs** after each run
5. **Keep dependencies updated** in workflows

## Monitoring

### Check Build Status
```bash
# Using GitHub CLI
gh run list --workflow=test.yml
gh run list --workflow=build-release.yml

# View specific run
gh run view <run-id>
```

### Download Artifacts
```bash
# List artifacts
gh run view <run-id> --log

# Download artifact
gh run download <run-id>
```

## Future Enhancements

Potential improvements to the CI/CD pipeline:

- [ ] Add automated testing on Raspberry Pi hardware
- [ ] Deploy to custom APT repository
- [ ] Add code coverage reporting
- [ ] Implement automated changelog generation
- [ ] Add security scanning (Dependabot, CodeQL)
- [ ] Create Docker images for testing
- [ ] Add performance benchmarks

## Support

For CI/CD issues:
1. Check workflow logs in Actions tab
2. Review this documentation
3. Test locally with same commands
4. Open an issue with workflow run URL
