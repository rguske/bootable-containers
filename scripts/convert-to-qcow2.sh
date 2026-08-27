#!/bin/bash
# Convert bootable container to QCOW2 disk image using bootc-image-builder
# Usage: ./convert-to-qcow2.sh [demo-name] [registry-url] [version]
# Requires: export USERNAME=<your-quay-username>
#
# NOTE: This script requires native Linux x86_64. On macOS with Apple Silicon,
# bootc-image-builder has limitations due to virtualized container storage.
# See README.md Demo 3 for macOS alternatives (GitHub Actions, Linux VM).

set -euo pipefail

DEMO_NAME="${1:-webserver}"
REGISTRY_URL="${2:-quay.io}"
VERSION="${3:-v1.0}"

if [[ -z "${USERNAME}" ]]; then
    echo "Error: USERNAME environment variable not set"
    echo ""
    echo "Usage:"
    echo "  export USERNAME=<your-quay-username>"
    echo "  $0 [demo-name] [registry-url] [version]"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DEMO_DIR="${PROJECT_DIR}/demos/${DEMO_NAME}"
OUTPUT_DIR="${DEMO_DIR}/output"

IMAGE_NAME="bootc-${DEMO_NAME}"
FULL_IMAGE="${REGISTRY_URL}/${USERNAME}/${IMAGE_NAME}:${VERSION}"

echo "================================================"
echo "Converting Bootable Container to QCOW2"
echo "================================================"
echo "Source Image: ${FULL_IMAGE}"
echo "Output Dir:   ${OUTPUT_DIR}"
echo "================================================"

cd "$DEMO_DIR"

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Pull the bootc image first (bootc-image-builder no longer pulls automatically)
echo ""
echo "Pulling source image..."
sudo podman pull "${FULL_IMAGE}"

# Run bootc-image-builder
echo ""
echo "Running bootc-image-builder..."
echo "This may take 10-20 minutes depending on your system."
echo ""

sudo podman run \
    --rm \
    -it \
    --privileged \
    --pull=newer \
    --security-opt label=type:unconfined_t \
    -v "$PWD/output":/output \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    quay.io/centos-bootc/bootc-image-builder:latest \
    --type qcow2 \
    "${FULL_IMAGE}"

echo ""
echo "================================================"
echo "Conversion complete!"
echo "QCOW2 image: ${OUTPUT_DIR}/qcow2/disk.qcow2"
echo "================================================"
echo ""
echo "Next steps:"
echo "  1. Package for OCP-V: ./package-for-ocpv.sh ${DEMO_NAME} ${REGISTRY_URL} ${VERSION}"
echo "  2. Or use directly with libvirt/KVM"
