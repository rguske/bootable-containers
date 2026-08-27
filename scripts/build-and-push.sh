#!/bin/bash
# Build and push bootable container images
# Usage: ./build-and-push.sh [demo-name] [registry-url] [version]
# Requires: export USERNAME=<your-quay-username>

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
    echo ""
    echo "Example:"
    echo "  export USERNAME=myuser"
    echo "  $0 webserver quay.io v1.0"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DEMO_DIR="${PROJECT_DIR}/demos/${DEMO_NAME}"

if [[ ! -d "$DEMO_DIR" ]]; then
    echo "Error: Demo directory not found: $DEMO_DIR"
    exit 1
fi

IMAGE_NAME="bootc-${DEMO_NAME}"
FULL_IMAGE="${REGISTRY_URL}/${USERNAME}/${IMAGE_NAME}:${VERSION}"

echo "================================================"
echo "Building Bootable Container Image"
echo "================================================"
echo "Demo:     ${DEMO_NAME}"
echo "Image:    ${FULL_IMAGE}"
echo "================================================"

cd "$DEMO_DIR"

# Build the image
echo ""
echo "[1/2] Building image..."
podman build -t "${FULL_IMAGE}" .

# Push the image
echo ""
echo "[2/2] Pushing image..."
podman push "${FULL_IMAGE}"

echo ""
echo "================================================"
echo "Build complete!"
echo "Image available at: ${FULL_IMAGE}"
echo "================================================"
echo ""
echo "Next steps:"
echo "  1. Convert to disk image: ./convert-to-qcow2.sh ${DEMO_NAME} ${REGISTRY_URL} ${VERSION}"
echo "  2. Or deploy directly with bootc switch on a running system"
