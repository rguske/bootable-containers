# Demo: Regular Container vs Bootable Container

This demo shows the key differences between a regular application container and a bootable container.

> **Prerequisite**: Build the bootc-webserver image first (see Demo 1 in main README).

## Quick Comparison

| Aspect | Regular Container | Bootable Container |
|--------|-------------------|-------------------|
| **Purpose** | Run a single application | Run a full operating system |
| **Init (PID 1)** | Application process | systemd |
| **Kernel** | Uses host kernel | Contains its own kernel |
| **Boot loader** | None | Contains GRUB/bootloader |
| **Filesystem** | Minimal, app-focused | Full OS with /boot, /usr, etc. |
| **Size** | ~50-500 MB | ~1-2 GB |
| **Updates** | Replace container | Atomic OS upgrade with rollback |

## Setup

```bash
export USERNAME=<your-quay-username>
```

## Demo Commands

### 1. Pull Both Images

```bash
# Regular container (UBI minimal)
podman pull registry.access.redhat.com/ubi9/ubi-minimal:latest

# Bootable container
podman pull quay.io/${USERNAME}/bootc-webserver:v1.0
```

### 2. Compare Image Sizes

```bash
podman images | grep -E "ubi-minimal|bootc-webserver"
```

**Expected output:**
```
registry.access.redhat.com/ubi9/ubi-minimal   latest   ...   ~100 MB
quay.io/${USERNAME}/bootc-webserver             v1.0     ...   ~1.5 GB
```

### 3. Check for Kernel

```bash
echo "=== Regular Container (no kernel) ==="
podman run --rm registry.access.redhat.com/ubi9/ubi-minimal:latest \
  ls -la /boot/ 2>/dev/null || echo "No /boot directory"

echo ""
echo "=== Bootable Container (has kernel) ==="
podman run --rm quay.io/${USERNAME}/bootc-webserver:v1.0 \
  ls -la /boot/
```

### 4. Check for Bootloader

```bash
echo "=== Regular Container (no bootloader) ==="
podman run --rm registry.access.redhat.com/ubi9/ubi-minimal:latest \
  ls /boot/grub2/ 2>/dev/null || echo "No bootloader"

echo ""
echo "=== Bootable Container (has GRUB) ==="
podman run --rm quay.io/${USERNAME}/bootc-webserver:v1.0 \
  ls /boot/grub2/ 2>/dev/null || ls /boot/loader/ 2>/dev/null || echo "Bootloader config present"
```

### 5. Check Init System (PID 1)

```bash
echo "=== Regular Container (app as PID 1) ==="
podman run --rm registry.access.redhat.com/ubi9/ubi-minimal:latest \
  cat /proc/1/comm 2>/dev/null || echo "Shows: bash or app process"

echo ""
echo "=== Bootable Container (systemd as PID 1) ==="
podman run --rm quay.io/${USERNAME}/bootc-webserver:v1.0 \
  readlink -f /sbin/init
```

### 6. Check for Kernel Modules

```bash
echo "=== Regular Container (no kernel modules) ==="
podman run --rm registry.access.redhat.com/ubi9/ubi-minimal:latest \
  ls /usr/lib/modules/ 2>/dev/null || echo "No kernel modules"

echo ""
echo "=== Bootable Container (has kernel modules) ==="
podman run --rm quay.io/${USERNAME}/bootc-webserver:v1.0 \
  ls /usr/lib/modules/
```

### 7. Check for systemd Services

```bash
echo "=== Regular Container (no systemd) ==="
podman run --rm registry.access.redhat.com/ubi9/ubi-minimal:latest \
  systemctl list-unit-files 2>/dev/null || echo "systemd not available"

echo ""
echo "=== Bootable Container (full systemd) ==="
podman run --rm quay.io/${USERNAME}/bootc-webserver:v1.0 \
  systemctl list-unit-files --state=enabled | head -20
```

### 8. Check bootc Tool

```bash
echo "=== Regular Container (no bootc) ==="
podman run --rm registry.access.redhat.com/ubi9/ubi-minimal:latest \
  which bootc 2>/dev/null || echo "bootc not present"

echo ""
echo "=== Bootable Container (bootc installed) ==="
podman run --rm quay.io/${USERNAME}/bootc-webserver:v1.0 \
  bootc --help | head -5
```

## All-in-One Demo Script

Run the complete comparison:

```bash
./compare.sh
```

## Key Takeaways

1. **Regular containers** are lightweight and run a single application using the host's kernel
2. **Bootable containers** are complete operating systems that can boot on bare metal or VMs
3. **Bootable containers** include kernel, bootloader, systemd, and firmware
4. **Bootable containers** support atomic updates and rollbacks via `bootc upgrade/rollback`
5. Both are built with the same tools (Podman, Containerfile) but serve different purposes
