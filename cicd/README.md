# CI/CD for Bootable Containers

This directory contains CI/CD pipeline configurations for building, testing, and deploying bootable containers to OpenShift Virtualization.

> **Note**: This project uses **CentOS Stream 9** bootc images (no subscription required).

## Overview

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           CI/CD Pipeline Flow                                    │
│                                                                                  │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐  │
│  │   Git    │───▶│  Build   │───▶│ Convert  │───▶│ Package  │───▶│  Deploy  │  │
│  │  Push    │    │ Container│    │ to QCOW2 │    │ for OCPV │    │   VM     │  │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘  │
│                                                                                  │
│  Triggers:       Podman/        bootc-image-     Container      GitOps/        │
│  - Push          Buildah        builder          with disk      ArgoCD         │
│  - PR                                                                           │
│  - Schedule                                                                     │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Pipeline Options

### 1. GitHub Actions (`github-actions/`)

Best for:
- Projects hosted on GitHub
- Teams already using GitHub ecosystem
- Simple setup with minimal infrastructure

Features:
- Build bootc container on push/PR
- Convert to QCOW2 using bootc-image-builder
- Push to Quay.io or other registries
- Trigger OpenShift deployment

### 2. OpenShift Pipelines / Tekton (`openshift-pipelines/`)

Best for:
- Full OpenShift-native CI/CD
- Air-gapped environments
- Complex multi-stage pipelines
- Integration with OpenShift security features

Features:
- Tekton Tasks and Pipelines
- PipelineRuns with parameters
- Integration with OpenShift internal registry
- Trigger via webhooks or EventListeners

### 3. GitOps with ArgoCD (`gitops/`)

Best for:
- Declarative, Git-driven deployments
- Multi-cluster deployments
- Automatic sync and drift detection
- Full audit trail

Features:
- ArgoCD Application definitions
- Automatic VM deployment on image updates
- Kustomize overlays for different environments

## Quick Start

### GitHub Actions

1. Copy `.github/workflows/bootc-build.yaml` to your repository
2. Configure repository secrets:
   - `REGISTRY_USERNAME`
   - `REGISTRY_PASSWORD`
   - `OPENSHIFT_SERVER`
   - `OPENSHIFT_TOKEN`
3. Push changes to trigger the pipeline

### OpenShift Pipelines

```bash
# Install pipelines
oc apply -f openshift-pipelines/

# Run the pipeline
oc create -f openshift-pipelines/pipelinerun.yaml
```

### GitOps

```bash
# Install ArgoCD Application
oc apply -f gitops/application.yaml
```

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `REGISTRY_URL` | Container registry URL | `quay.io` |
| `REGISTRY_USERNAME` | Registry username | `myuser` |
| `IMAGE_NAME` | Image name | `bootc-webserver` |
| `IMAGE_TAG` | Image tag | `v1.0` or `$(git rev-parse --short HEAD)` |
| `STORAGE_CLASS` | OCP storage class | `ocs-storagecluster-ceph-rbd` |
