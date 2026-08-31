# Bootc Upgrade and Rollback Demo Design

**Date:** 2026-08-31  
**Status:** Approved  
**Author:** Assistant with Robert Guske

## Overview

Add a live upgrade/rollback demo to the bootable containers project. The demo shows the bootc upgrade process by switching from v1.0 (red theme) to v1.1 (purple theme) and optionally rolling back.

## Goals

- Demonstrate `bootc switch` command for upgrading to a new image version
- Demonstrate `bootc rollback` command for reverting to the previous version
- Provide clear visual feedback of version changes via color theme and version badge
- Keep implementation simple with parameterized builds

## Non-Goals

- Automatic updates (out of scope for this demo)
- Multiple theme support beyond red/purple
- CI/CD automation for building both versions

## Design

### Approach

Use Containerfile build arguments with `sed` replacement to parameterize:
- Theme colors (primary, dark, light variants)
- Version number
- Subtitle text

This allows building multiple versions from a single Containerfile.

### File Changes

#### index.html

Replace hardcoded values with placeholders:

| Current Value | Placeholder |
|---------------|-------------|
| `#ee0000` | `THEME_COLOR` |
| `#a30000` | `THEME_COLOR_DARK` |
| `#ff4d4d` | `THEME_COLOR_LIGHT` |
| (new) | `APP_VERSION` |
| "The Operating System as a Container Image" | `APP_SUBTITLE` |

Add version badge in header (top-right corner of the card, inside `demo-header` div):
```html
<span class="version-badge">vAPP_VERSION</span>
```

Add CSS for the badge:
```css
.version-badge {
    position: absolute;
    top: 1rem;
    right: 1rem;
    background: THEME_COLOR;
    color: white;
    padding: 0.25rem 0.75rem;
    border-radius: 1rem;
    font-size: 0.9rem;
    font-weight: 600;
}
.demo-header {
    position: relative;  /* Added for badge positioning */
}
```

#### Containerfile

Add build arguments with defaults for v1.0:

```dockerfile
ARG THEME_COLOR="#ee0000"
ARG THEME_COLOR_DARK="#a30000"
ARG THEME_COLOR_LIGHT="#ff4d4d"
ARG VERSION="1.0"
ARG SUBTITLE="The Operating System as a Container Image"
```

Add sed replacement after copying index.html:

```dockerfile
RUN sed -i \
    -e "s/THEME_COLOR_DARK/${THEME_COLOR_DARK}/g" \
    -e "s/THEME_COLOR_LIGHT/${THEME_COLOR_LIGHT}/g" \
    -e "s/THEME_COLOR/${THEME_COLOR}/g" \
    -e "s/APP_VERSION/${VERSION}/g" \
    -e "s/APP_SUBTITLE/${SUBTITLE}/g" \
    /usr/share/www/html/index.html
```

Update version label:
```dockerfile
ARG VERSION
LABEL version="${VERSION}"
```

### Version Definitions

| Version | Theme | Colors | Subtitle |
|---------|-------|--------|----------|
| v1.0 | Red | #ee0000, #a30000, #ff4d4d | The Operating System as a Container Image |
| v1.1 | Purple | #7b2cbf, #5a189a, #9d4edd | Version 1.1 - Purple Edition |

### Build Commands

**v1.0 (default, red):**
```bash
podman build --platform linux/amd64 \
  -t quay.io/${USERNAME}/bootc-webserver:v1.0 .
```

**v1.1 (purple):**
```bash
podman build --platform linux/amd64 \
  --build-arg THEME_COLOR="#7b2cbf" \
  --build-arg THEME_COLOR_DARK="#5a189a" \
  --build-arg THEME_COLOR_LIGHT="#9d4edd" \
  --build-arg VERSION="1.1" \
  --build-arg SUBTITLE="Version 1.1 - Purple Edition" \
  -t quay.io/${USERNAME}/bootc-webserver:v1.1 .
```

### Demo Flow

**Pre-demo setup:**
1. Build and push both v1.0 and v1.1 images
2. Convert v1.0 to QCOW2 on Linux host
3. Deploy VM with v1.0

**Live demo:**

1. Show v1.0 running (red theme, "v1.0" badge)
2. SSH into VM: `virtctl ssh bootc-user@bootc-webserver -n bootable-containers-demo`
3. Check status: `sudo bootc status`
4. Upgrade: `sudo bootc switch quay.io/${USERNAME}/bootc-webserver:v1.1`
5. Reboot: `sudo systemctl reboot`
6. Show v1.1 running (purple theme, "v1.1" badge, new subtitle)
7. (Optional) Rollback: `sudo bootc rollback && sudo systemctl reboot`
8. Show v1.0 restored

### Documentation Updates

Add new section to README.md: "Demo 4: Upgrade and Rollback"

Contents:
- Building multiple versions
- Upgrade procedure
- Rollback procedure
- Expected `bootc status` output

## Testing

1. Build v1.0, verify red theme and version badge
2. Build v1.1, verify purple theme, version badge, and subtitle
3. Run upgrade on VM, verify theme change persists after reboot
4. Run rollback, verify return to v1.0 theme

## Implementation Order

1. Update index.html with placeholders and version badge
2. Update Containerfile with ARGs and sed commands
3. Test builds locally (container inspection)
4. Update README.md with Demo 4 section
5. Test full upgrade/rollback flow on OCP-V
