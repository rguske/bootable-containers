#!/bin/bash
# Compare regular container vs bootable container
# Usage: ./compare.sh

set -euo pipefail

if [[ -z "${USERNAME:-}" ]]; then
    echo "Error: USERNAME environment variable not set"
    echo "Run: export USERNAME=<your-quay-username>"
    exit 1
fi

REGULAR_IMAGE="registry.access.redhat.com/ubi9/ubi-minimal:latest"
BOOTC_IMAGE="quay.io/$USERNAME/bootc-webserver:v1.0"

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  $1${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_section() {
    echo -e "${BLUE}>>> $1${NC}"
}

# Ensure images are available
print_header "Pulling Images"
podman pull $REGULAR_IMAGE --quiet
podman pull $BOOTC_IMAGE --quiet
echo "Done."

# 1. Image Sizes
print_header "1. Image Size Comparison"
echo -e "${GREEN}Regular Container:${NC}"
podman images $REGULAR_IMAGE --format "  {{.Repository}}:{{.Tag}} - {{.Size}}"
echo ""
echo -e "${GREEN}Bootable Container:${NC}"
podman images $BOOTC_IMAGE --format "  {{.Repository}}:{{.Tag}} - {{.Size}}"

# 2. Kernel
print_header "2. Kernel Presence"
print_section "Regular Container"
podman run --rm $REGULAR_IMAGE ls -la /boot/ 2>/dev/null || echo "  No /boot directory - uses host kernel"
echo ""
print_section "Bootable Container"
podman run --rm $BOOTC_IMAGE ls /boot/vmlinuz* 2>/dev/null | head -3 || \
podman run --rm $BOOTC_IMAGE ls /boot/ 2>/dev/null | head -5

# 3. Init System
print_header "3. Init System (PID 1)"
print_section "Regular Container"
echo "  Default entrypoint runs application directly (no init system)"
echo ""
print_section "Bootable Container"
echo -n "  Init system: "
podman run --rm $BOOTC_IMAGE readlink -f /sbin/init

# 4. Kernel Modules
print_header "4. Kernel Modules"
print_section "Regular Container"
podman run --rm $REGULAR_IMAGE ls /usr/lib/modules/ 2>/dev/null || echo "  No kernel modules directory"
echo ""
print_section "Bootable Container"
echo "  Kernel modules present:"
podman run --rm $BOOTC_IMAGE ls /usr/lib/modules/ | head -3

# 5. systemd Services
print_header "5. systemd Services"
print_section "Regular Container"
podman run --rm $REGULAR_IMAGE systemctl 2>/dev/null || echo "  systemd not available"
echo ""
print_section "Bootable Container"
echo "  Enabled services:"
podman run --rm $BOOTC_IMAGE systemctl list-unit-files --state=enabled 2>/dev/null | grep -E "httpd|sshd|firewalld" || \
podman run --rm $BOOTC_IMAGE ls /etc/systemd/system/*.wants/ 2>/dev/null | head -5

# 6. bootc Tool
print_header "6. bootc Management Tool"
print_section "Regular Container"
podman run --rm $REGULAR_IMAGE which bootc 2>/dev/null || echo "  bootc not present - cannot manage OS updates"
echo ""
print_section "Bootable Container"
podman run --rm $BOOTC_IMAGE bootc --version

# Summary
print_header "Summary"
cat << 'EOF'
┌─────────────────────┬─────────────────────┬─────────────────────┐
│ Feature             │ Regular Container   │ Bootable Container  │
├─────────────────────┼─────────────────────┼─────────────────────┤
│ Purpose             │ Run application     │ Run full OS         │
│ Kernel              │ Host kernel         │ Own kernel          │
│ Init system         │ None (app is PID 1) │ systemd             │
│ Size                │ ~100 MB             │ ~1.5 GB             │
│ Can boot as VM      │ No                  │ Yes                 │
│ Atomic OS updates   │ No                  │ Yes (bootc)         │
│ Rollback            │ No                  │ Yes (bootc)         │
└─────────────────────┴─────────────────────┴─────────────────────┘
EOF

echo ""
echo "Demo complete!"
