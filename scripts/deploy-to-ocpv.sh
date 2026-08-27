#!/bin/bash
# Deploy bootable container VM to OpenShift Virtualization
# Usage: ./deploy-to-ocpv.sh [registry-url] [version]
# Requires: export USERNAME=<your-quay-username>

set -euo pipefail

REGISTRY_URL="${1:-quay.io}"
VERSION="${2:-v1.0}"

if [[ -z "${USERNAME}" ]]; then
    echo "Error: USERNAME environment variable not set"
    echo ""
    echo "Usage:"
    echo "  export USERNAME=<your-quay-username>"
    echo "  $0 [registry-url] [version]"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OCP_DIR="${PROJECT_DIR}/openshift-virtualization"

DISK_IMAGE="${REGISTRY_URL}/${USERNAME}/bootc-webserver:${VERSION}-disk"

echo "================================================"
echo "Deploying to OpenShift Virtualization"
echo "================================================"
echo "Disk Image: ${DISK_IMAGE}"
echo "================================================"

# Check if logged into OpenShift
if ! oc whoami &>/dev/null; then
    echo "Error: Not logged into OpenShift cluster."
    echo "Please run: oc login <cluster-url>"
    exit 1
fi

echo ""
echo "Cluster: $(oc whoami --show-server)"
echo "User:    $(oc whoami)"
echo ""

# Create namespace
echo "[1/5] Creating namespace..."
oc apply -f "${OCP_DIR}/namespace.yaml"

# Update DataVolume with correct image
echo "[2/5] Creating DataVolume..."
sed "s|docker://quay.io/YOUR_USERNAME/bootc-webserver:v1.0-disk|docker://${DISK_IMAGE}|g" \
    "${OCP_DIR}/datavolume.yaml" | oc apply -f -

# Wait for DataVolume import
echo "[3/5] Waiting for disk import (this may take a few minutes)..."
oc wait --for=condition=Ready datavolume/bootc-webserver-disk \
    -n bootable-containers-demo \
    --timeout=600s || {
    echo "Warning: DataVolume not ready yet. Check status with:"
    echo "  oc get dv -n bootable-containers-demo"
}

# Create VirtualMachine
echo "[4/5] Creating VirtualMachine..."
oc apply -f "${OCP_DIR}/virtualmachine.yaml"

# Create Service and Route
echo "[5/5] Creating Service and Route..."
oc apply -f "${OCP_DIR}/service.yaml"
oc apply -f "${OCP_DIR}/route.yaml"

echo ""
echo "================================================"
echo "Deployment initiated!"
echo "================================================"
echo ""
echo "Monitor status with:"
echo "  oc get vm -n bootable-containers-demo"
echo "  oc get vmi -n bootable-containers-demo"
echo ""
echo "Get route URL:"
echo "  oc get route bootc-webserver -n bootable-containers-demo -o jsonpath='{.spec.host}'"
echo ""
echo "Access VM console:"
echo "  virtctl console bootc-webserver -n bootable-containers-demo"
echo ""
echo "SSH credentials: bootc-user / redhat"
