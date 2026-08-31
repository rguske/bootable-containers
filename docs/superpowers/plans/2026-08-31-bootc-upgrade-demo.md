# Bootc Upgrade Demo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add parameterized theming to the webserver demo, enabling v1.0 (red) and v1.1 (purple) builds to demonstrate bootc upgrade/rollback.

**Architecture:** Modify index.html to use placeholders for colors, version, and subtitle. Modify Containerfile to accept build args and use sed to replace placeholders at build time. Add Demo 4 section to README.

**Tech Stack:** HTML/CSS, Containerfile (Podman), sed, bootc

## Global Constraints

- Maintain backward compatibility: building without args produces v1.0 (red)
- All sed replacements happen in Containerfile, not at runtime
- Purple theme colors: #7b2cbf (primary), #5a189a (dark), #9d4edd (light)
- Red theme colors: #ee0000 (primary), #a30000 (dark), #ff4d4d (light)

---

### Task 1: Update index.html with Placeholders and Version Badge

**Files:**
- Modify: `demos/webserver/index.html`

**Interfaces:**
- Consumes: Nothing
- Produces: HTML file with placeholders `THEME_COLOR`, `THEME_COLOR_DARK`, `THEME_COLOR_LIGHT`, `APP_VERSION`, `APP_SUBTITLE`

- [ ] **Step 1: Add version badge CSS**

Add this CSS inside the `<style>` block, after the `.demo-header` rule (around line 43):

```css
.demo-header {
    position: relative;
    text-align: center;
    padding: var(--pf-t--global--spacer--xl) 0;
    background: linear-gradient(180deg, rgba(238, 0, 0, 0.1) 0%, transparent 100%);
    border-radius: var(--pf-t--global--border--radius--medium) var(--pf-t--global--border--radius--medium) 0 0;
}

.version-badge {
    position: absolute;
    top: 1rem;
    right: 1rem;
    background: var(--rh-red);
    color: white;
    padding: 0.25rem 0.75rem;
    border-radius: 1rem;
    font-size: 0.9rem;
    font-weight: 600;
}
```

- [ ] **Step 2: Replace color values with placeholders**

In the `:root` CSS block (lines 10-14), replace:

```css
:root {
    --rh-red: THEME_COLOR;
    --rh-red-dark: THEME_COLOR_DARK;
    --rh-red-light: THEME_COLOR_LIGHT;
}
```

- [ ] **Step 3: Add version badge HTML**

Inside the `demo-header` div (after line 165), add the version badge:

```html
<div class="demo-header">
    <span class="version-badge">vAPP_VERSION</span>
    <div class="demo-emoji pulse">🚀</div>
```

- [ ] **Step 4: Replace subtitle with placeholder**

Change line 168 from:

```html
<p class="demo-subtitle">The Operating System as a Container Image</p>
```

to:

```html
<p class="demo-subtitle">APP_SUBTITLE</p>
```

- [ ] **Step 5: Verify placeholders visually**

Open `demos/webserver/index.html` in a browser. It will look broken (placeholders visible, no colors). This is expected.

- [ ] **Step 6: Commit**

```bash
git add demos/webserver/index.html
git commit -m "feat(webserver): add placeholders for parameterized theming"
```

---

### Task 2: Update Containerfile with Build Args and sed Replacement

**Files:**
- Modify: `demos/webserver/Containerfile`

**Interfaces:**
- Consumes: index.html with placeholders from Task 1
- Produces: Containerfile that accepts `THEME_COLOR`, `THEME_COLOR_DARK`, `THEME_COLOR_LIGHT`, `VERSION`, `SUBTITLE` build args

- [ ] **Step 1: Add build args at top of Containerfile**

After the `FROM` line (line 9), add:

```dockerfile
# Theme customization build args (defaults to v1.0 red theme)
ARG THEME_COLOR="#ee0000"
ARG THEME_COLOR_DARK="#a30000"
ARG THEME_COLOR_LIGHT="#ff4d4d"
ARG VERSION="1.0"
ARG SUBTITLE="The Operating System as a Container Image"
```

- [ ] **Step 2: Add sed replacement after COPY index.html**

After the `COPY index.html` line (line 34), add:

```dockerfile
# Apply theme customization
RUN sed -i \
    -e "s|THEME_COLOR_DARK|${THEME_COLOR_DARK}|g" \
    -e "s|THEME_COLOR_LIGHT|${THEME_COLOR_LIGHT}|g" \
    -e "s|THEME_COLOR|${THEME_COLOR}|g" \
    -e "s|APP_VERSION|${VERSION}|g" \
    -e "s|APP_SUBTITLE|${SUBTITLE}|g" \
    /usr/share/www/html/index.html
```

Note: Order matters! Replace `THEME_COLOR_DARK` and `THEME_COLOR_LIGHT` before `THEME_COLOR` to avoid partial matches.

- [ ] **Step 3: Update version label**

Change the LABEL block (lines 40-42) to:

```dockerfile
ARG VERSION
LABEL name="bootc-webserver" \
      version="${VERSION}" \
      description="CentOS Stream 9 bootc-based Apache web server"
```

- [ ] **Step 4: Commit**

```bash
git add demos/webserver/Containerfile
git commit -m "feat(webserver): add build args for theme customization"
```

---

### Task 3: Test v1.0 Build (Red Theme)

**Files:**
- None (testing only)

**Interfaces:**
- Consumes: Containerfile and index.html from Tasks 1-2
- Produces: Verified v1.0 image with red theme

- [ ] **Step 1: Build v1.0 image**

```bash
cd demos/webserver
podman build --platform linux/amd64 -t bootc-webserver:v1.0-test .
```

Expected: Build completes successfully.

- [ ] **Step 2: Extract and verify index.html**

```bash
podman run --rm bootc-webserver:v1.0-test cat /usr/share/www/html/index.html | grep -E "(--rh-red:|version-badge|demo-subtitle)"
```

Expected output should contain:
- `--rh-red: #ee0000;`
- `--rh-red-dark: #a30000;`
- `--rh-red-light: #ff4d4d;`
- `v1.0` in version badge
- `The Operating System as a Container Image` in subtitle

- [ ] **Step 3: Clean up test image**

```bash
podman rmi bootc-webserver:v1.0-test
```

---

### Task 4: Test v1.1 Build (Purple Theme)

**Files:**
- None (testing only)

**Interfaces:**
- Consumes: Containerfile and index.html from Tasks 1-2
- Produces: Verified v1.1 image with purple theme

- [ ] **Step 1: Build v1.1 image with purple theme**

```bash
cd demos/webserver
podman build --platform linux/amd64 \
  --build-arg THEME_COLOR="#7b2cbf" \
  --build-arg THEME_COLOR_DARK="#5a189a" \
  --build-arg THEME_COLOR_LIGHT="#9d4edd" \
  --build-arg VERSION="1.1" \
  --build-arg SUBTITLE="Version 1.1 - Purple Edition" \
  -t bootc-webserver:v1.1-test .
```

Expected: Build completes successfully.

- [ ] **Step 2: Extract and verify index.html**

```bash
podman run --rm bootc-webserver:v1.1-test cat /usr/share/www/html/index.html | grep -E "(--rh-red:|version-badge|demo-subtitle)"
```

Expected output should contain:
- `--rh-red: #7b2cbf;`
- `--rh-red-dark: #5a189a;`
- `--rh-red-light: #9d4edd;`
- `v1.1` in version badge
- `Version 1.1 - Purple Edition` in subtitle

- [ ] **Step 3: Clean up test image**

```bash
podman rmi bootc-webserver:v1.1-test
```

- [ ] **Step 4: Commit verification note (optional)**

No code changes, but if all tests pass, proceed to documentation.

---

### Task 5: Add Demo 4 Section to README

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: Build commands from design spec
- Produces: New "Demo 4: Upgrade and Rollback" section in README

- [ ] **Step 1: Add Demo 4 to Table of Contents**

Find the Table of Contents section and add after `Demo 3`:

```markdown
- [Demo 4: Upgrade and Rollback](#demo-4-upgrade-and-rollback)
```

- [ ] **Step 2: Add Demo 4 section**

Add this section after the "Demo 3: Deploy to OpenShift Virtualization" section (before "CI/CD Integration"):

```markdown
---

## Demo 4: Upgrade and Rollback

Demonstrate bootc's atomic upgrade and rollback capabilities by switching between image versions.

### Prerequisites

- VM running v1.0 from Demo 3
- Both v1.0 and v1.1 images pushed to your registry

### Step 1: Build Both Versions

**v1.0 (red theme, default):**
```bash
cd demos/webserver

podman build --platform linux/amd64 \
  -t quay.io/${USERNAME}/bootc-webserver:v1.0 .

podman push quay.io/${USERNAME}/bootc-webserver:v1.0
```

**v1.1 (purple theme):**
```bash
podman build --platform linux/amd64 \
  --build-arg THEME_COLOR="#7b2cbf" \
  --build-arg THEME_COLOR_DARK="#5a189a" \
  --build-arg THEME_COLOR_LIGHT="#9d4edd" \
  --build-arg VERSION="1.1" \
  --build-arg SUBTITLE="Version 1.1 - Purple Edition" \
  -t quay.io/${USERNAME}/bootc-webserver:v1.1 .

podman push quay.io/${USERNAME}/bootc-webserver:v1.1
```

### Step 2: Verify Current Version

Open the web server URL and confirm you see the **red theme** with **v1.0** badge.

SSH into the VM:
```bash
virtctl ssh bootc-user@bootc-webserver -n bootable-containers-demo
```

Check current bootc status:
```bash
sudo bootc status
```

### Step 3: Upgrade to v1.1

```bash
sudo bootc switch quay.io/${USERNAME}/bootc-webserver:v1.1
```

Reboot to apply:
```bash
sudo systemctl reboot
```

After reboot, refresh the browser. You should see:
- **Purple theme**
- **v1.1** badge
- Subtitle: "Version 1.1 - Purple Edition"

### Step 4: Rollback to v1.0

SSH back into the VM:
```bash
virtctl ssh bootc-user@bootc-webserver -n bootable-containers-demo
```

Rollback:
```bash
sudo bootc rollback
sudo systemctl reboot
```

After reboot, refresh the browser. You should see the **red theme** and **v1.0** badge restored.

### Key Takeaways

- **Atomic updates**: The entire OS updates as one unit
- **Instant rollback**: Previous version is preserved and ready to boot
- **No package drift**: Every boot is from a known, tested image
```

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: add Demo 4 for bootc upgrade and rollback"
```

---

### Task 6: Final Commit and Push

**Files:**
- None (git operations only)

**Interfaces:**
- Consumes: All changes from Tasks 1-5
- Produces: Changes pushed to GitHub

- [ ] **Step 1: Review all changes**

```bash
git log --oneline -5
```

Expected: 3-4 commits from this implementation.

- [ ] **Step 2: Push to GitHub**

```bash
git push origin main
```

- [ ] **Step 3: Verify on GitHub**

Open https://github.com/rguske/bootable-containers and verify:
- README shows Demo 4 section
- Containerfile has build args
- index.html has placeholders

---

## Post-Implementation: Full E2E Test (Optional)

After pushing, perform a full end-to-end test:

1. Build v1.0 on Mac, push to Quay
2. Convert to QCOW2 on Linux host
3. Package and push disk image
4. Deploy VM
5. Build and push v1.1
6. Perform upgrade on running VM
7. Verify purple theme appears
8. Perform rollback
9. Verify red theme restored
