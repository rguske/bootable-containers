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

1. Move the workflow to where GitHub Actions looks for it:

   ```bash
   mkdir -p .github/workflows
   mv cicd/github-actions/bootc-build.yaml .github/workflows/bootc-build.yaml
   ```

2. Configure secrets in GitHub (not in this repository). Open the GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**, and add:
   - `REGISTRY_USERNAME`
   - `REGISTRY_PASSWORD` — required to **push** images. A public registry only allows unauthenticated **pulls**; GitHub Actions still logs in to push.
   - `OPENSHIFT_SERVER` — cluster API URL used by the **deploy** job (`oc login`). Example: `https://api.cluster.example.com:6443`. Get it with `oc whoami --show-server`. Skip this secret if you only build and push.
   - `OPENSHIFT_TOKEN` — API token for that same login (`oc whoami --show-token`, or a service-account token). Skip this secret if you only build and push.

   These values stay in GitHub. Do not commit them, and do not put them in the workflow file. A public registry means OpenShift does not need a pull secret; it does not remove `REGISTRY_PASSWORD` from this list.

3. Push changes to trigger the pipeline. The workflow runs on push to `main` or `develop` (when `demos/webserver/**` or the workflow file change), on pull requests to `main`, or from **Actions → Build Bootable Container → Run workflow**.

**Expected outcome**

- GitHub → **Actions** shows a run named **Build Bootable Container**.
- The **Build Bootable Container Image** job succeeds and pushes `quay.io/<REGISTRY_USERNAME>/bootc-webserver:<tag>`. The tag is UTC date-time (`YYYYMMDD-HHMM`, for example `20260827-1505`). A manual run can override it; `latest` is not used.
- On `main` only, **Convert to QCOW2 (x86_64)** then pushes `quay.io/<REGISTRY_USERNAME>/bootc-webserver:<tag>-disk`.
- On `main` only, **Deploy to OpenShift Virtualization** logs in with `OPENSHIFT_SERVER` / `OPENSHIFT_TOKEN`, applies the VM manifests, and prints the route URL. If those two secrets are not set, this job fails; build and convert can still succeed.
- Pull requests run the build job only. Convert and deploy do not run until the change is on `main`.

### OpenShift Pipelines

Image tags use the same UTC `YYYYMMDD-HHMM` scheme as GitHub Actions. Leave `image-tag` empty to generate it at run time.

```bash
# Install pipelines
oc apply -f openshift-pipelines/

# Run the pipeline
oc create -f openshift-pipelines/pipelinerun.yaml
```

### GitOps

Pin the disk image to a UTC date-time tag (for example `20260827-1505-disk`), not `latest`. Image Updater selects the newest tag matching `YYYYMMDD-HHMM-disk`.

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
| `IMAGE_TAG` | Image tag | `20260827-1505` (UTC `YYYYMMDD-HHMM`) |
| `STORAGE_CLASS` | OCP storage class | `ocs-storagecluster-ceph-rbd` |
