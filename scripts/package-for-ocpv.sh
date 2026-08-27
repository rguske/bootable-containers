#!/bin/bash
# Package QCOW2 disk image as a container for OpenShift Virtualization
# Usage: ./package-for-ocpv.sh [demo-name] [registry-url] [version]
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
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DEMO_DIR="${PROJECT_DIR}/demos/${DEMO_NAME}"

IMAGE_NAME="bootc-${DEMO_NAME}"
DISK_IMAGE="${REGISTRY_URL}/${USERNAME}/${IMAGE_NAME}:${VERSION}-disk"

# Check if QCOW2 exists
QCOW2_PATH="${DEMO_DIR}/output/qcow2/disk.qcow2"
if [[ ! -f "$QCOW2_PATH" ]]; then
    echo "Error: QCOW2 image not found at: ${QCOW2_PATH}"
    echo "Run convert-to-qcow2.sh first."
    exit 1
fi

echo "================================================"
echo "Packaging QCOW2 for OpenShift Virtualization"
echo "================================================"
echo "QCOW2 Source: ${QCOW2_PATH}"
echo "Disk Image:   ${DISK_IMAGE}"
echo "================================================"

cd "$DEMO_DIR"

# Check for OCP-V Containerfile
if [[ ! -f "Containerfile.ocpv" ]]; then
    echo "Creating Containerfile.ocpv..."
    cat > Containerfile.ocpv << 'EOF'
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest AS builder
ADD --chown=107:107 output/qcow2/disk.qcow2 /disk/
RUN chmod 0440 /disk/*

FROM scratch
COPY --from=builder /disk/* /disk/
EOF
fi

# Build the disk image container
echo ""
echo "[1/2] Building disk image container..."
podman build -f Containerfile.ocpv -t "${DISK_IMAGE}" .

# Push the disk image
echo ""
echo "[2/2] Pushing disk image..."
podman push "${DISK_IMAGE}"

echo ""
echo "================================================"
echo "Packaging complete!"
echo "Disk image available at: ${DISK_IMAGE}"
echo "================================================"
echo ""
echo "Next steps:"
echo "  1. Update openshift-virtualization/datavolume.yaml with your image URL"
echo "  2. Deploy to OpenShift:"
echo "     oc apply -f ../openshift-virtualization/namespace.yaml"
echo "     oc apply -f ../openshift-virtualization/datavolume.yaml"
echo "     oc apply -f ../openshift-virtualization/virtualmachine.yaml"
echo "     oc apply -f ../openshift-virtualization/service.yaml"
echo "     oc apply -f ../openshift-virtualization/route.yaml"
