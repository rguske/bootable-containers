# Edge Base on Bootable Containers

This demo shows a base CentOS Stream 9 bootc image prepared for edge deployments.

> **Note**: MicroShift packages are only available in RHEL with subscription. This example provides a base image structure that can be extended with alternatives like k3s.

## Set Environment Variable

```bash
export USERNAME=<your-quay-username>
```

## Build

```bash
podman build -t quay.io/${USERNAME}/bootc-edge-base:v1.0 .
podman push quay.io/${USERNAME}/bootc-edge-base:v1.0
```

## Convert to Disk Image

> **Note**: This requires native Linux x86_64. On macOS with Apple Silicon, `bootc-image-builder` has limitations due to virtualized container storage. See the main README Demo 3 for macOS alternatives.

```bash
# Pull the image first (bootc-image-builder no longer pulls automatically)
sudo podman pull quay.io/${USERNAME}/bootc-edge-base:v1.0

mkdir -p output

sudo podman run \
  --rm -it --privileged \
  --pull=newer \
  --security-opt label=type:unconfined_t \
  -v "$PWD/output":/output \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --type qcow2 \
  quay.io/${USERNAME}/bootc-edge-base:v1.0
```

## Credentials

- **User**: `admin`
- **Password**: `redhat`
