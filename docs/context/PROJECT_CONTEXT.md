# CUDA Sentinel Project Context

## Purpose

CUDA Sentinel is an early-stage GPU operations console and installer prototype
for detecting CUDA/NVIDIA health issues and proposing targeted remediation.

## Current State

- The dashboard is a mocked React/TypeScript component stored in legacy `.py`-named files.
- The latest installer is `install_cuda_sentinel_v0.1.5.sh`.
- The repository does not yet contain the Python agent/API payload expected by the installer.
- The current roadmap is at the repository root: [`ROADMAP.md`](../../ROADMAP.md).

## Continuation Point

Implement the runtime agent/API contract and safe remediation boundary before
connecting the dashboard to live data. Follow the P0 items in the root roadmap.

## Safety Constraints

Do not run the installer on a development workstation. Remediation must be
allowlisted, approval-gated, auditable, and dry-run by default before any
production execution path is added.
