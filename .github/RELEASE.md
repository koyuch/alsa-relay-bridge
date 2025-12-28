# Release Process

This document describes how to create a new release of the ALSA Relay Bridge package.

## Semantic Versioning

This project follows [Semantic Versioning](https://semver.org/):
- **MAJOR** version for incompatible API changes
- **MINOR** version for new functionality in a backwards compatible manner
- **PATCH** version for backwards compatible bug fixes

## Release Steps

### 1. Update Version

Update the version in the following files:

```bash
# Update VERSION file
echo "1.0.1" > VERSION

# Update debian/changelog
dch -v 1.0.1 "Description of changes"
# Or manually edit debian/changelog
```

### 2. Update Changelog

Edit [`debian/changelog`](../debian/changelog) to document changes:

```
alsa-relay-bridge (1.0.1) stable; urgency=medium

  * Bug fix: Description of fix
  * Feature: Description of new feature
  * Improvement: Description of improvement

 -- ALSA Relay Bridge Team <maintainer@example.com>  [Date in RFC 2822 format]
```

### 3. Commit Changes

```bash
git add VERSION debian/changelog
git commit -m "Bump version to 1.0.1"
git push origin main
```

### 4. Create and Push Tag

```bash
# Create annotated tag
git tag -a v1.0.1 -m "Release version 1.0.1"

# Push tag to trigger GitHub Actions
git push origin v1.0.1
```

### 5. Automated Build

Once the tag is pushed, GitHub Actions will automatically:
1. Build the Debian package
2. Run tests and validation
3. Create a GitHub Release
4. Attach the `.deb` package to the release

### 6. Verify Release

1. Go to the [Releases page](../../releases)
2. Verify the new release is created
3. Download and test the `.deb` package
4. Update release notes if needed

## Manual Release (Alternative)

If you need to create a release manually:

```bash
# Build the package locally
./build-deb.sh

# Create release on GitHub
gh release create v1.0.1 \
  --title "Release v1.0.1" \
  --notes "Release notes here" \
  ../alsa-relay-bridge_*.deb
```

## Testing Before Release

Before creating a release tag, test the build:

```bash
# Test local build
./build-deb.sh

# Test installation
sudo apt install ../alsa-relay-bridge_*.deb

# Verify service
systemctl status alsa-relay-volume.service

# Test functionality
amixer -c BossDAC set Master 50%

# Uninstall
sudo apt remove alsa-relay-bridge
```

## Hotfix Process

For urgent fixes:

1. Create a hotfix branch from the tag:
```bash
git checkout -b hotfix/1.0.1 v1.0.0
```

2. Make the fix and update version to 1.0.1

3. Merge back to main:
```bash
git checkout main
git merge hotfix/1.0.1
```

4. Create new tag:
```bash
git tag -a v1.0.1 -m "Hotfix: Description"
git push origin v1.0.1
```

## Release Checklist

- [ ] Version updated in `VERSION` file
- [ ] Changelog updated in `debian/changelog`
- [ ] Changes committed and pushed
- [ ] Tag created and pushed
- [ ] GitHub Actions build successful
- [ ] Release created on GitHub
- [ ] Package tested on target hardware
- [ ] Documentation updated if needed
